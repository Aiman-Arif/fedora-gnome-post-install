#!/bin/bash

# Function to check if the distribution is Fedora
check_distribution() {
    if [ -f /etc/os-release ]; then
        source /etc/os-release  # Load OS release information
        if [[ "${ID}" != "fedora" ]]; then
            echo "Error: This script is intended for Fedora Linux. Detected distribution: ${ID}"
            exit 1
        fi
    else
        echo "Error: /etc/os-release not found. Cannot determine distribution."
        exit 1
    fi
}

# Function to check if Zenity is installed
check_zenity() {
    if ! command -v zenity &> /dev/null; then
        echo -e "\nExecuting: Installing zenity"
        sudo dnf install -y zenity  # Install Zenity if not already installed
        echo -e "Process Completed!\n"
    fi
}

# Function to improve DNF speed by updating the configuration file
imp_dnf() {
    local dnf_conf="/etc/dnf/dnf.conf"
    # Add settings to dnf.conf if they do not already exist
    sudo grep -qxF 'fastestmirror=1' $dnf_conf || echo 'fastestmirror=1' | sudo tee -a $dnf_conf
    sudo grep -qxF 'max_parallel_downloads=10' $dnf_conf || echo 'max_parallel_downloads=10' | sudo tee -a $dnf_conf
    sudo grep -qxF 'deltarpm=True' $dnf_conf || echo 'deltarpm=True' | sudo tee -a $dnf_conf
    sudo grep -qxF 'defaultyes=True' $dnf_conf || echo 'defaultyes=True' | sudo tee -a $dnf_conf
}

# Function to add RPM Fusion repositories and update the system
add_rpm_fusion () {
    # Install RPM Fusion repositories
    sudo dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm
    sudo dnf groupupdate -y core  # Update core group
    sudo dnf upgrade -y --refresh  # Upgrade all packages
}

# Function to update firmware
update_firmware () {
    sudo fwupdmgr get-devices  # Get list of devices
    sudo fwupdmgr refresh --force  # Refresh metadata
    sudo fwupdmgr get-updates  # Get list of updates
    sudo fwupdmgr update  # Apply updates
}

# Function to install media codecs
install_media_codecs () {
    # Update multimedia groups and swap ffmpeg-free with ffmpeg
    sudo dnf groupupdate -y "core" "multimedia" "sound-and-video" --setopt="install_weak_deps=False" --exclude="PackageKit-gstreamer-plugin" --allowerasing
    sudo dnf swap -y "ffmpeg-free" "ffmpeg" --allowerasing
    # Install GStreamer plugins and other multimedia packages
    sudo dnf install -y gstreamer1-plugins-{bad-*,good-*,base} gstreamer1-plugin-openh264 gstreamer1-libav --exclude=gstreamer1-plugins-bad-free-devel ffmpeg gstreamer-ffmpeg
    sudo dnf install -y lame* --exclude=lame-devel
    sudo dnf group upgrade -y --with-optional Multimedia
}

# Function to install commonly used applications
install_commonly_used_apps () {
    # Install applications via DNF and Flatpak
    sudo dnf install -y fastfetch timeshift vlc cascadia-code-nf-fonts
    flatpak install -y one.ablaze.floorp net.nokyan.Resources
}

# Function to install personal applications for Aiman
personal_apps () {
    # Add launcher.moe Flatpak repository and Microsoft GPG key
    flatpak remote-add --if-not-exists launcher.moe https://gol.launcher.moe/gol.launcher.moe.flatpakrepo
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    # Add Visual Studio Code repository
    echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" | sudo tee /etc/yum.repos.d/vscode.repo > /dev/null
    dnf check-update
    # Install development tools and other applications
    sudo dnf group install -y "C Development Tools and Libraries" "Development Tools"
    sudo dnf install -y unzip p7zip p7zip-plugins unrar code
    flatpak install -y com.bitwarden.desktop io.github.shiftey.Desktop org.telegram.desktop
    flatpak install -y moe.launcher.the-honkers-railway-launcher
}

# Function to install theme related apps for GNOME
related_theme_gnome () {
    # Override Flatpak filesystem permissions
    cd ~/
    mkdir .themes .icons
    sudo flatpak override --filesystem=$HOME/.themes
    sudo flatpak override --filesystem=$HOME/.icons
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    # Enable pop-os extension
    sudo dnf install -y gnome-shell-extension-pop-shell xprop
    # Enable theme related apps
    sudo dnf install -y gnome-tweaks
    flatpak install -y io.github.realmazharhussain.GdmSettings com.mattjakeman.ExtensionManager ca.desrt.dconf-editor
    # Install Bibata cursor theme
    sudo dnf copr enable -y peterwu/rendezvous
    sudo dnf install -y bibata-cursor-themes
    # Install Papirus icon theme
    wget -qO- https://git.io/papirus-icon-theme-install | sh
    # Set themes
    gsettings set org.gnome.desktop.interface icon-theme "Papirus-Dark"
    gsettings set org.gnome.desktop.interface cursor-theme "Bibata-Modern-Classic"
}

# Function to install theme related apps for KDE
related_theme_kde () {
    # Override Flatpak filesystem permissions
    cd ~/
    mkdir .themes .icons
    sudo flatpak override --filesystem=$HOME/.themes
    sudo flatpak override --filesystem=$HOME/.icons
    sudo flatpak override --filesystem=xdg-config/gtk-4.0
    # Install Bibata cursor theme
    sudo dnf copr enable -y peterwu/rendezvous
    sudo dnf install -y bibata-cursor-themes
    # Install Papirus icon theme
    wget -qO- https://git.io/papirus-icon-theme-install | sh
}

# Function to install themes
install_theme () {
    # Install and configure GTK theme
    sudo dnf install -y gnome-themes-extra gtk-murrine-engine sassc glib2-devel
    cd ~/
    git clone https://github.com/vinceliuice/Colloid-gtk-theme.git
    cd Colloid-gtk-theme
    ./install.sh --tweaks gruvbox black rimless float
    ./install.sh --tweaks gruvbox black rimless float -c dark -l
    cd ~/.themes
    sudo cp -r ./. /usr/share/themes
    cd ~/
    # Install Papirus folder icon theme
    wget -qO- https://git.io/papirus-folders-install | sh
    papirus-folders -C blue --theme Papirus-Dark
}

# Function to install ohmybash
install_ohmybash () {
    cd ~/.local/share
    mkdir fonts
    # Install required fonts
    cd ~/
    git clone https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    # Install OhMyBash
    bash -c "$(curl -fsSL https://raw.githubusercontent.com/ohmybash/oh-my-bash/master/tools/install.sh)"
    cd ~/
    rm -rf fonts
}

# Function to remove bloatware
remove_bloatware () {
    # Remove unwanted applications
    sudo dnf remove -y gnome-boxes gnome-connections gnome-contacts gnome-logs gnome-tour mediawriter gnome-abrt gnome-system-monitor gnome-extensions-app firefox totem
}

# Define custom text and corresponding multi-line commands as arrays
custom_ops=(
    "Improve DNF Speed by updating conf file"
    "Adding RPM Fusion"
    "Updating firmware"
    "Installing media codecs"
    "Installing commonly used apps"
    "Installing personal apps for Aiman"
    "Installing theme related apps"
    "Installing GTK themes"
    "Installing OhMyBash"
    "Removing bloatware"
)

# Define custom commands as function names
custom_commands=(
    "imp_dnf"
    "add_rpm_fusion"
    "update_firmware"
    "install_media_codecs"
    "install_commonly_used_apps"
    "personal_apps"
    "related_theme_gnome"
    "install_theme"
    "install_ohmybash"
    "remove_bloatware"
)

# Define user DE
user_de=("GNOME" "KDE")

# Define the log file
log_file="command_output.log"

# Check if the log file exists and remove it if it does
if [ -f "$log_file" ]; then
    rm "$log_file"  # Remove the existing log file
fi

# Function to handle Zenity dialogs
zenity_dialogs () {
    local user_de=("${!1}")
    local custom_ops=("${!2}")
    local custom_commands=("${!3}")

    # Install flathub repository
    flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

    # Select DE using Zenity
    user_select_de=$(zenity --list --title="Select Your Desktop Environment" --column="DE" "${user_de[@]}" --width=500 --height=500 )

    if [ -z "$user_select_de" ]; then
        exit 1  # Exit if no DE was selected
    fi

    # Modify commands for KDE
    if [ "$user_select_de" == "KDE" ]; then
        # Adjust commands for KDE environment
        # Remove setup_theme function for KDE
        unset 'custom_ops[7]'
        unset 'custom_commands[7]'
        custom_commands[6]=related_theme_kde
        custom_commands[8]="sudo dnf remove -y pim* akonadi* akregator korganizer kolourpaint kmail kmag kmines kmahjongg kmousetool kmouth kpat kruler kamoso krdc krfb ktnef kaddressbook konversation kf5-akonadi-server mariadb mariadb-backup mariadb-common mediawriter gnome-abrt neochat firefox"
    fi

    zenity --question --text="You have selected ${user_select_de} as your DE. Is this correct?" --ok-label="Yes" --cancel-label="No" --width=300 --height=150
    if [ $? -ne 0 ]; then
        exit 1  # Exit if the DE selection is not confirmed
    fi

    # Add "Select All" option to custom_ops
    custom_ops=("Select All" "${custom_ops[@]}")

    # Select commands to run using Zenity with multi-select option
    selected_indices=$(zenity --list --title="Select Commands to Run: Multi Select using Ctrl + Alt" --column="Available commands" "${custom_ops[@]}" --multiple --width=500 --height=500)

    if [ -z "$selected_indices" ]; then
        zenity --error --text="No commands selected. Exiting." --width=300 --height=150
        exit 1  # Exit if no commands are selected
    fi

    # Convert selected options to indices
    IFS='|' read -ra indices <<< "$selected_indices"

    # Check if "Select All" was chosen
    if [[ " ${indices[@]} " =~ " Select All " ]]; then
        indices=("${custom_ops[@]:1}")  # Select all options excluding "Select All"
    fi

    # Show selected options in an info message with commas separating them
    joined_indices=$(printf "%s, " "${indices[@]}")
    joined_indices="${joined_indices%, }"  # Remove the trailing comma and space
    zenity --info --text="Your selected options: ${joined_indices}" --width=300 --height=150

    # Execute selected commands
    for selected_option in "${indices[@]}"; do
        for ((i = 1; i < ${#custom_ops[@]}; i++)); do
            if [ "${custom_ops[i]}" == "$selected_option" ]; then
                echo -e "\nExecuting: ${custom_ops[i]}"
                (${custom_commands[i-1]}) | tee -a "$log_file"  # Log the command output
                echo -e "Process Completed!\n"
            fi
        done
    done

    sudo dnf upgrade -y --refresh  # Upgrade all packages
    sudo dnf autoremove -y  # Remove unnecessary packages

    zenity --question --text="It is recommended to reboot. Reboot now?" --ok-label="Yes" --cancel-label="No" --width=300 --height=150
    if [ $? -eq 0 ]; then
        reboot  # Reboot the system if the user agrees
    fi
}

# Call the check distribution function
check_distribution
# Call the zenity check function
check_zenity
# Call the Zenity dialog function with arrays of custom text and multi-line commands
zenity_dialogs user_de[@] custom_ops[@] custom_commands[@]
