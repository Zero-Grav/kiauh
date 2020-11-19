check_moonraker(){
  status_msg "Checking for Moonraker service ..."
  if [ "$(systemctl list-units --full -all -t service --no-legend | grep -F "moonraker.service")" ]; then
    ok_msg "Moonraker service found!"; echo
    MOONRAKER_SERVICE_FOUND="true"
  else
    warn_msg "Moonraker service not found!"
    warn_msg "Please install Moonraker first!"; echo
    MOONRAKER_SERVICE_FOUND="false"
  fi
}

get_user_selection_webui(){
  #ask user for webui default macros
  while true; do
    unset ADD_WEBUI_MACROS
    echo
    top_border
    echo -e "| It is recommended to have some important macros to    |"
    echo -e "| have full functionality of the web interface.         |"
    blank_line
    echo -e "| If you do not have such macros, you can choose to     |"
    echo -e "| install the suggested default macros now.             |"
    bottom_border
    read -p "${cyan}###### Add the recommended macros? (Y/n):${default} " yn
    case "$yn" in
      Y|y|Yes|yes|"")
        echo -e "###### > Yes"
        ADD_WEBUI_MACROS="true"
        break;;
      N|n|No|no)
        echo -e "###### > No"
        ADD_WEBUI_MACROS="false"
        break;;
      *)
        print_unkown_cmd
        print_msg && clear_msg;;
    esac
  done
}

install_routine_klipper_ui(){
  get_user_selection_webui
  #check if moonraker is already installed
  check_moonraker
  if [ "$MOONRAKER_SERVICE_FOUND" = "true" ]; then
    #check for other enabled web interfaces
    unset SET_LISTEN_PORT
    detect_enabled_sites
    #check if another site already listens to port 80
    $1_port_check
    #creating the mainsail nginx cfg
    set_nginx_cfg $1
    #test_nginx "$SET_LISTEN_PORT"
    locate_printer_cfg && read_printer_cfg $1
    install_webui_macros
    select_klipper_ui $1 && install_klipper_ui
  fi
}

install_webui_macros(){
  #copy webui_macros.cfg
  if [ "$ADD_WEBUI_MACROS" = "true" ]; then
    status_msg "Create webui_macros.cfg ..."
    if [ ! -f ${HOME}/klipper_config/webui_macros.cfg ]; then
      cp ${HOME}/kiauh/resources/webui_macros.cfg ${HOME}/klipper_config
      ok_msg "File created!"
    else
      warn_msg "File already exists! Skipping ..."
    fi
  fi
  write_printer_cfg
}

mainsail_port_check(){
  if [ "$MAINSAIL_ENABLED" = "false" ]; then
    if [ "$SITE_ENABLED" = "true" ]; then
      status_msg "Detected other enabled interfaces:"
      [ "$OCTOPRINT_ENABLED" = "true" ] && echo -e "   ${cyan}● OctoPrint - Port: $OCTOPRINT_PORT${default}"
      [ "$FLUIDD_ENABLED" = "true" ] && echo -e "   ${cyan}● Fluidd - Port: $FLUIDD_PORT${default}"
      [ "$DWC2_ENABLED" = "true" ] && echo -e "   ${cyan}● DWC2 - Port: $DWC2_PORT${default}"
      if [ "$FLUIDD_PORT" = "80" ] || [ "$DWC2_PORT" = "80" ] || [ "$OCTOPRINT_PORT" = "80" ]; then
        PORT_80_BLOCKED="true"
        select_mainsail_port
      fi
    else
      DEFAULT_PORT=$(grep listen ${SRCDIR}/kiauh/resources/mainsail_nginx.cfg | head -1 | sed 's/^\s*//' | cut -d" " -f2 | cut -d";" -f1)
      SET_LISTEN_PORT=$DEFAULT_PORT
    fi
    SET_NGINX_CFG="true"
  else
    SET_NGINX_CFG="false"
  fi
}

fluidd_port_check(){
  if [ "$FLUIDD_ENABLED" = "false" ]; then
    if [ "$SITE_ENABLED" = "true" ]; then
      status_msg "Detected other enabled interfaces:"
      [ "$OCTOPRINT_ENABLED" = "true" ] && echo "   ${cyan}● OctoPrint - Port: $OCTOPRINT_PORT${default}"
      [ "$MAINSAIL_ENABLED" = "true" ] && echo "   ${cyan}● Mainsail - Port: $MAINSAIL_PORT${default}"
      [ "$DWC2_ENABLED" = "true" ] && echo "   ${cyan}● DWC2 - Port: $DWC2_PORT${default}"
      if [ "$MAINSAIL_PORT" = "80" ] || [ "$DWC2_PORT" = "80" ] || [ "$OCTOPRINT_PORT" = "80" ]; then
        PORT_80_BLOCKED="true"
        select_fluidd_port
      fi
    else
      DEFAULT_PORT=$(grep listen ${SRCDIR}/kiauh/resources/fluidd_nginx.cfg | head -1 | sed 's/^\s*//' | cut -d" " -f2 | cut -d";" -f1)
      SET_LISTEN_PORT=$DEFAULT_PORT
    fi
    SET_NGINX_CFG="true"
  else
    SET_NGINX_CFG="false"
  fi
}

select_mainsail_port(){
  if [ "$PORT_80_BLOCKED" = "true" ]; then
    echo
    top_border
    echo -e "|                    ${red}!!!WARNING!!!${default}                      |"
    echo -e "| ${red}You need to choose a different port for Mainsail!${default}     |"
    echo -e "| ${red}The following web interface is listening at port 80:${default}  |"
    blank_line
    [ "$OCTOPRINT_PORT" = "80" ] && echo "|  ● OctoPrint                                          |"
    [ "$FLUIDD_PORT" = "80" ] && echo "|  ● Fluidd                                             |"
    [ "$DWC2_PORT" = "80" ] && echo "|  ● DWC2                                               |"
    blank_line
    echo -e "| Make sure you don't choose a port which was already   |"
    echo -e "| assigned to one of the other web interfaces!          |"
    blank_line
    echo -e "| Be aware: there is ${red}NO${default} sanity check for the following  |"
    echo -e "| input. So make sure to choose a valid port!           |"
    bottom_border
    while true; do
      read -p "${cyan}Please enter a new Port:${default} " NEW_PORT
      if [ "$NEW_PORT" != "$FLUIDD_PORT" ] && [ "$NEW_PORT" != "$DWC2_PORT" ] && [ "$NEW_PORT" != "$OCTOPRINT_PORT" ]; then
        echo "Setting port $NEW_PORT for Mainsail!"
        SET_LISTEN_PORT=$NEW_PORT
        break
      else
        echo "That port is already taken! Select a different one!"
      fi
    done
  fi
}

select_fluidd_port(){
  if [ "$PORT_80_BLOCKED" = "true" ]; then
    echo
    top_border
    echo -e "|                    ${red}!!!WARNING!!!${default}                      |"
    echo -e "| ${red}You need to choose a different port for Fluidd!${default}       |"
    echo -e "| ${red}The following web interface is listening at port 80:${default}  |"
    blank_line
    [ "$OCTOPRINT_PORT" = "80" ] && echo "|  ● OctoPrint                                          |"
    [ "$MAINSAIL_PORT" = "80" ] && echo "|  ● Mainsail                                           |"
    [ "$DWC2_PORT" = "80" ] && echo "|  ● DWC2                                               |"
    blank_line
    echo -e "| Make sure you don't choose a port which was already   |"
    echo -e "| assigned to one of the other web interfaces!          |"
    blank_line
    echo -e "| Be aware: there is ${red}NO${default} sanity check for the following  |"
    echo -e "| input. So make sure to choose a valid port!           |"
    bottom_border
    while true; do
      read -p "${cyan}Please enter a new Port:${default} " NEW_PORT
      if [ "$NEW_PORT" != "$MAINSAIL_PORT" ] && [ "$NEW_PORT" != "$DWC2_PORT" ] && [ "$NEW_PORT" != "$OCTOPRINT_PORT" ]; then
        echo "Setting port $NEW_PORT for Fluidd!"
        SET_LISTEN_PORT=$NEW_PORT
        break
      else
        echo "That port is already taken! Select a different one!"
      fi
    done
  fi
}

select_klipper_ui(){
  [[ $1 == mainsail ]] && ui="mainsail" && ui_repo_id="240875926" && ui_dir=${HOME}/$1
  [[ $1 == fluidd ]] && ui="fluidd" && ui_repo_id="295836951" && ui_dir=${HOME}/$1
  #[[ $1 == dwc2 ]] && ui="dwc2" && ui_repo_id="28820678" && ui_dir=${HOME}/sdcard/web
  ui_repo="https://api.github.com/repositories/$ui_repo_id/releases"
}

get_klipper_ui_version(){
  ui_version=$(curl -s $ui_repo | grep tag_name | cut -d'"' -f4 | cut -d"v" -f2 | head -1)
}

install_klipper_ui(){
  get_klipper_ui_version
  #download urls
  ui_dl_url=$(curl -s $ui_repo | grep browser_download_url | cut -d'"' -f4 | head -1)
  #installation
  [ -d $ui_dir ] && rm -rf $ui_dir
  [ ! -d $ui_dir ] && mkdir -p $ui_dir
  cd $ui_dir && wget $ui_dl_url && ok_msg "Download complete!"
  status_msg "Extracting archive ..."
  unzip -q -o *.zip
  #more unzipping needed when installing dwc2
  if [[ $ui == dwc2 ]]; then
    for f_ in $(find . | grep '.gz'); do gunzip -f ${f_}; done
  fi
  status_msg "Writing version to file ..." && echo $ui_version > $ui_dir/version && ok_msg "Done!"
  #patch moonraker.conf to apply cors domains if needed (currently only used by Fluidd)
  if [[ $ui == fluidd ]]; then
    backup_moonraker_conf && patch_moonraker
  fi
  status_msg "Remove downloaded archive ..." && rm -rf *.zip && ok_msg "Installation complete!"
}

patch_moonraker(){
  status_msg "Patching moonraker.conf ..."
  mr_conf=${HOME}/moonraker.conf
  # remove the now deprecated enable_cors option from moonraker.conf if it still exists
  if [ "$(grep "^enable_cors:" $mr_conf)" ]; then
    line="$(grep -n "^enable_cors:" ~/moonraker.conf | cut -d":" -f1)d"
    sed -i "$line" $mr_conf && mr_restart="true"
  fi
  # looking for a cors_domain entry in moonraker.conf
  if [ ! "$(grep "^cors_domains:$" $mr_conf)" ]; then
    #find trusted_clients line number and subtract one, to insert cors_domains later
    line="$(grep -n "^trusted_clients:$" $mr_conf | cut -d":" -f1)i"
    sed -i "$line cors_domains:" $mr_conf && mr_restart="true"
  fi
  if [ "$(grep "^cors_domains:$" $mr_conf)" ]; then
    hostname=$(hostname -I | cut -d" " -f1)
    url1="\ \ \ \ http://*.local"
    url2="\ \ \ \ http://app.fluidd.xyz"
    url3="\ \ \ \ https://app.fluidd.xyz"
    url4="\ \ \ \ http://$hostname:*"
    #find cors_domains line number and add one, to insert urls later
    line="$(expr $(grep -n "cors_domains:" $mr_conf | cut -d":" -f1) + 1)i"
    [ ! "$(grep -E '^\s+http:\/\/\*\.local$' $mr_conf)" ] && sed -i "$line $url1" $mr_conf && mr_restart="true"
    [ ! "$(grep -E '^\s+http:\/\/app\.fluidd\.xyz$' $mr_conf)" ] && sed -i "$line $url2" $mr_conf && mr_restart="true"
    [ ! "$(grep -E '^\s+https:\/\/app\.fluidd\.xyz$' $mr_conf)" ] && sed -i "$line $url3" $mr_conf && mr_restart="true"
    [ ! "$(grep -E '^\s+http:\/\/([0-9]{1,3}\.){3}[0-9]{1,3}' $mr_conf)" ] && sed -i "$line $url4" $mr_conf && mr_restart="true"
  fi
  #restart moonraker service if mr_restart was set to true
  if [[ $mr_restart == "true" ]]; then
    ok_msg "Patching done!" && restart_moonraker
  else
    ok_msg "No patching was needed!"
  fi
}