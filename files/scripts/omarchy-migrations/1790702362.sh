echo "Verify Fedora's compiler and Qt development packages"
rpm -q gcc gcc-c++ make qt6-qtbase-devel qt6-qtdeclarative-devel \
  qt6-qtmultimedia-devel qt6-qtsvg-devel qt6-qtwayland-devel libavcodec-free-devel >/dev/null
