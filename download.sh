# Source this script instead of run it

extract_pkg() {
    local prefix_dir="$HOME/prefix"
    mkdir -p "$prefix_dir"
    local tmp_dir="$(mktemp -d)"
    # echo "[*] Extracting package $1 to '$tmp_dir'"
    rpm2cpio "$1" | cpio -idm -D "$tmp_dir"
    # echo "[*] Fixing symlinks..."
    find "$tmp_dir" -type l -lname '/*' | while read link_name; do
        local link_dst_name="$prefix_dir$(readlink "$link_name")"
        # echo "    - $link_name -> $link_dst_name"
        ln -sf "$link_dst_name" "$link_name"
    done
    echo "[*] Installing files of $1 to $prefix_dir"
    rsync -a "$tmp_dir/" "$prefix_dir"
    # echo "[*] Cleaning up..."
    rm -rf "$tmp_dir"
}

install_yumdownloader() {
    echo "[*] No yumdownloader on local machine. Installing it now..."
    local tmp_dir="$(mktemp -d)"
    wget -O "$tmp_dir/yum-utils-4.0.18-4.el8.noarch.rpm.rpm" "http://mirror.centos.org/centos/8-stream/BaseOS/aarch64/os/Packages/yum-utils-4.0.18-4.el8.noarch.rpm"
    extract_pkg "$tmp_dir/yum-utils-4.0.18-4.el8.noarch.rpm.rpm"
    rm -rf "$tmp_dir"
}

install_pkg() {
    which yumdownloader > /dev/null 2>&1 0>&1 || install_yumdownloader
    local tmp_dir="$(mktemp -d)"
    echo "[*] Resolving packages for $1..."
    export PATH=$HOME/prefix/usr/bin:$PATH
    yumdownloader --destdir "$tmp_dir" --resolve "$1"
    
    if [ "$?" -eq "0" ]; then
        echo "[*] Installing packages..."
        for pkg in $tmp_dir/*.rpm; do
            echo "[*] Installing package $pkg..."
            extract_pkg "$pkg"
        done
    fi
    
    rm -rf "$tmp_dir"
}

install_pkg mesa-libGLU-devel
