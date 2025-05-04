#!/bin/bash
# Arch Linux Post-Installation Script

# Exit immediately if a command exits with a non-zero status.
set -e

echo "Starting Arch Linux post-installation setup..."

# Install yay AUR helper
echo "Installing yay..."
if ! command -v yay &> /dev/null; then
    cd ~
    sudo pacman -S --needed --noconfirm git base-devel
    git clone https://aur.archlinux.org/yay.git
    cd yay
    makepkg -si --noconfirm
    cd ~
    rm -rf yay
    echo "yay installed successfully."
else
    echo "yay is already installed."
fi

# Install CachyOS repos
echo "Installing CachyOS repositories..."
cd ~
curl https://mirror.cachyos.org/cachyos-repo.tar.xz -o cachyos-repo.tar.xz
tar xvf cachyos-repo.tar.xz
cd cachyos-repo
# Assuming cachyos-repo.sh handles sudo internally or prompts if needed
./cachyos-repo.sh
cd ~
rm -rf cachyos-repo*
echo "CachyOS repositories installed."

# Install Chaotic-AUR repo
echo "Installing Chaotic-AUR repository..."
sudo pacman-key --recv-key 3056513887B78AEB --keyserver keyserver.ubuntu.com || echo "Failed to receive Chaotic-AUR key, attempting another keyserver..." && sudo pacman-key --recv-key 3056513887B78AEB --keyserver hkp://keyserver.ubuntu.com:80
sudo pacman-key --lsign-key 3056513887B78AEB
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-keyring.pkg.tar.zst'
sudo pacman -U --noconfirm 'https://cdn-mirror.chaotic.cx/chaotic-aur/chaotic-mirrorlist.pkg.tar.zst'
echo "Chaotic-AUR repository installed."

# Add Chaotic-AUR to pacman.conf
echo "Adding Chaotic-AUR to /etc/pacman.conf..."
if ! grep -q "\[chaotic-aur\]" /etc/pacman.conf; then
    echo "[chaotic-aur]" | sudo tee -a /etc/pacman.conf
    echo "Include = /etc/pacman.d/chaotic-mirrorlist" | sudo tee -a /etc/pacman.conf
    echo "Chaotic-AUR added to pacman.conf."
else
    echo "Chaotic-AUR already configured in pacman.conf."
fi

# Update system
echo "Updating system with yay..."
yay -Syyu --noconfirm

# Install essential packages
echo "Installing essential packages..."
yay -S --needed --noconfirm fzf zoxide starship neovim zsh paru-bin fastfetch pfetch-rs-bin github-cli nodejs rustup go gcc

# Install Rust toolchains
echo "Installing Rust stable and nightly toolchains..."
rustup install stable nightly
rustup default stable # Set stable as default

# Install Oh My Zsh
echo "Installing Oh My Zsh..."
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    # Run Oh My Zsh installer non-interactively
    CHSH=no RUNZSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    echo "Oh My Zsh installed."
else
    echo "Oh My Zsh is already installed."
fi

# Install Oh My Zsh plugins
echo "Installing Oh My Zsh plugins..."
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM}/plugins/zsh-autosuggestions || echo "zsh-autosuggestions already cloned or failed."
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM}/plugins/zsh-syntax-highlighting || echo "zsh-syntax-highlighting already cloned or failed."
echo "Oh My Zsh plugins installed."

# Copy .zshrc
echo "Copying .zshrc configuration..."
# Assuming the script is run from the directory containing .zshrc
cp -f ./.zshrc ~/.zshrc
echo ".zshrc copied."

# Clone Neovim configuration
echo "Cloning Neovim configuration..."
if [ ! -d "$HOME/.config/nvim" ]; then
    git clone https://github.com/davidbasilefilho/basile.nvim ~/.config/nvim
    echo "Neovim configuration cloned."
else
    echo "Neovim configuration directory already exists at ~/.config/nvim."
fi

# Ask to install recommended browser
echo "Checking for recommended browser..."
read -p "Would you like to install the recommended browser (zen-browser-bin)? (y/N): " install_browser
if [[ "$install_browser" =~ ^[Yy]$ ]]; then
    echo "Installing zen-browser-bin..."
    yay -S --needed --noconfirm zen-browser-bin
    echo "zen-browser-bin installed."
else
    echo "Skipping recommended browser installation."
fi

echo "Post-installation script finished!"
echo "Please reboot or log out and log back in for all changes to take effect."
echo "Consider changing your default shell to zsh with: chsh -s $(which zsh)"

