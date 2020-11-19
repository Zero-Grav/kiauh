install_ui(){
  top_border
  echo -e "|     ${green}~~~~~~~~~~~ [ Installation Menu ] ~~~~~~~~~~~${default}     | "
  hr
  echo -e "|  You need this menu usually only for installing       | "
  echo -e "|  all necessary dependencies for the various           | "
  echo -e "|  functions on a completely fresh system.              | "
  hr
  echo -e "|  Firmware:             |  Webinterface:               | "
  echo -e "|  1) [Klipper]          |  3) [DWC2]                   | "
  echo -e "|                        |  4) [Mainsail]               | "
  echo -e "|  Klipper API:          |  5) [Fluidd]                 | "
  echo -e "|  2) [Moonraker]        |  6) [Octoprint]              | "
  quit_footer
}

install_menu(){
  print_header
  install_ui
  while true; do
    read -p "${cyan}Perform action:${default} " action; echo
    case "$action" in
      1)
        clear
        print_header
        install_klipper
        print_msg && clear_msg
        install_ui;;
      2)
        clear
        print_header
        install_moonraker
        print_msg && clear_msg
        install_ui;;
      3)
        clear
        print_header
        install_dwc2
        print_msg && clear_msg
        install_ui;;
      4)
        clear
        print_header
        install_routine_klipper_ui "mainsail"
        print_msg && clear_msg
        install_ui;;
      5)
        clear
        print_header
        install_routine_klipper_ui "fluidd"
        print_msg && clear_msg
        install_ui;;
      6)
        clear
        print_header
        install_octoprint
        print_msg && clear_msg
        install_ui;;
      Q|q)
        clear; main_menu; break;;
      *)
        clear
        print_header
        print_unkown_cmd
        print_msg && clear_msg
        install_ui;;
    esac
  done
  install_menu
}
