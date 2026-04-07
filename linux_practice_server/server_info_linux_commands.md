## OS and Distribution Information

* cat /etc/os-release: The most universal way to view distribution details (name, version, ID) on modern Linux systems.
* hostnamectl: Provides a high-level summary including the OS name, kernel version, and architecture in one view.
* lsb_release -a: Prints specific LSB (Linux Standard Base) information such as the distributor ID, release, and codename.
* cat /etc/issue: Displays the distribution name and version often shown at the login prompt.
* uname -a: Shows all basic system info, including the kernel name, version, and the machine hardware architecture.
* uname -r: Specifically prints only the current Linux kernel release version. [2, 3, 4, 5, 6, 7, 8, 9, 10] 

## CPU and Architecture Information

* lscpu: Gathers and displays a comprehensive summary of CPU architecture details like the number of cores, threads, sockets, and cache sizes.
* arch: Simply prints the machine hardware architecture (e.g., x86_64).
* cat /proc/cpuinfo: Displays raw, detailed data for every logical processor core, including model name and flags.
* nproc: Quickly prints the total number of available processing units (CPU cores).
* getconf _NPROCESSORS_ONLN: Displays the number of processors currently online/used by the OS.
* cpufreq-info: Shows real-time information regarding CPU frequency scaling and speed settings. [6, 8, 11, 12, 13, 14, 15, 16] 

## Software
- `glibc`: ldd --version

## Hardware Summaries and Real-Time Monitoring [17] 

* lshw: A powerful tool that lists detailed information about all hardware components, including CPU, memory, and disks.
* dmidecode -t processor: Reads DMI (SMBIOS) tables to show physical hardware specs like the CPU model and supported upgrades.
* inxi -F: Generates a full system report including CPU, distro, kernel, and desktop environment.
* top / htop: Provides a real-time, interactive view of CPU and memory usage by active processes.
* neofetch: A popular tool for a stylized, visual summary of your OS and hardware specs. [8, 10, 15, 17, 18, 19, 20, 21, 22] 

Would you like the exact syntax for any of these commands to filter for a specific detail, like just the CPU core count?

[1] [https://www.geeksforgeeks.org](https://www.geeksforgeeks.org/linux-unix/10-linux-commands-to-collect-system-and-hardware-information/)
[2] [https://www.dade2.net](https://www.dade2.net/kb/10-linux-commands-to-know-the-system/)
[3] [https://superuser.com](https://superuser.com/questions/303981/what-is-the-linux-command-to-find-out-hardware-info)
[4] [https://www.reddit.com](https://www.reddit.com/r/linux4noobs/comments/c61l8i/what_isare_commands_that_i_would_use_to_find_out/)
[5] [https://www.linkedin.com](https://www.linkedin.com/posts/lunguflorin_11-commands-to-view-linux-hardware-details-activity-7425391850557071360-_9ds)
[6] [https://www.cyberciti.biz](https://www.cyberciti.biz/open-source/linux-commands-to-know-the-system/)
[7] [https://superuser.com](https://superuser.com/questions/303981/what-is-the-linux-command-to-find-out-hardware-info)
[8] [https://www.tecmint.com](https://www.tecmint.com/commands-to-collect-system-and-hardware-information-in-linux/)
[9] [https://www.tutorialspoint.com](https://www.tutorialspoint.com/article/10-linux-commands-to-collect-system-and-hardware-information#:~:text=Table_title:%20Command%20Usage%20Summary%20Table_content:%20header:%20%7C,%7C%20Key%20Options:%20%2Dh%20%28human%20readable%29%20%7C)
[10] [https://medium.com](https://medium.com/technology-hits/basic-linux-commands-to-check-hardware-and-system-information-62a4436d40db)
[11] [https://www.redhat.com](https://www.redhat.com/en/blog/get-cpu-information-linux)
[12] [https://linuxize.com](https://linuxize.com/post/get-cpu-information-on-linux/#:~:text=Table_title:%20Quick%20Reference%20Table_content:%20header:%20%7C%20Command,Show%20per%2DCPU%20core%20and%20thread%20layout%20%7C)
[13] [https://www.geeksforgeeks.org](https://www.geeksforgeeks.org/linux-unix/hardware-and-system-information-commands-in-linux/)
[14] [https://www.cyberciti.biz](https://www.cyberciti.biz/faq/linux-display-cpu-information-number-of-cpus-and-their-speed/)
[15] [https://www.geeksforgeeks.org](https://www.geeksforgeeks.org/linux-unix/check-linux-cpu-information/)
[16] [https://www.geeksforgeeks.org](https://www.geeksforgeeks.org/linux-unix/how-to-check-how-many-cpus-are-there-in-linux-system/)
[17] [https://opensource.com](https://opensource.com/article/19/9/linux-commands-hardware-information#:~:text=Table_title:%20Quick%20reference%20chart%20Table_content:%20header:%20%7C,%2D%2Dshort%20%2D%2Dor%2D%2D%20lshw%20%2Dshort:%20uname%20%2Da%20%7C)
[18] [https://www.tecmint.com](https://www.tecmint.com/commands-to-collect-system-and-hardware-information-in-linux/)
[19] [https://rexxinfo.org](https://rexxinfo.org/howard_fosdick_articles/linux_hardware_commands/linux_commands_to_discover_computer_hardware.html#:~:text=Table_title:%20Quick%20Reference%20Chart%20Table_content:%20header:%20%7C,%2D%2Dshort%20%2D%2Dor%2D%2D%20lshw%20%2Dshort:%20uname%20%2Da%20%7C)
[20] [https://icinga.com](https://icinga.com/blog/linux-check-cpu-usage/)
[21] [https://linuxconfig.org](https://linuxconfig.org/linux-basic-health-check-commands)
[22] [https://www.reddit.com](https://www.reddit.com/r/linuxquestions/comments/vqptfv/how_to_check_my_system_info/)
