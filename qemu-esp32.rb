class QemuEsp32 < Formula
  desc "Emulator for Esp32"
  homepage "https://github.com/espressif/qemu.git/wiki"
  license "GPL-2.0-only"
  revision 1
  head "https://github.com/espressif/qemu.git", branch: "esp-develop"

  keg_only :versioned_formula

  depends_on "libtool" => :build
  depends_on "meson" => :build
  depends_on "ninja" => :build
  depends_on "pkg-config" => :build
  depends_on "libgcrypt" => :build

  depends_on "glib"
  depends_on "gnutls"
  depends_on "jpeg"
  depends_on "libpng"
  depends_on "libslirp"
  depends_on "libssh"
  depends_on "libusb"
  depends_on "lzo"
  depends_on "ncurses"
  depends_on "nettle"
  depends_on "pixman"
  depends_on "snappy"
  depends_on "vde"

  on_linux do
    depends_on "gcc"
  end

  fails_with gcc: "5"

  if Hardware::CPU.arm?
    patch do
      url "https://patchwork.kernel.org/series/548227/mbox/"
      sha256 "5b9c9779374839ce6ade1b60d1377c3fc118bc43e8482d0d3efa64383e11b6d3"
    end
  end

  def install
    ENV["LIBTOOL"] = "glibtool"

    args = %W[
      --prefix=#{prefix}
      --cc=#{ENV.cc}
      --host-cc=#{ENV.cc}
      --disable-bsd-user
      --disable-guest-agent
      --target-list=xtensa-softmmu,xtensaeb-softmmu
      --enable-curses
      --enable-libssh
      --enable-gcrypt
      --enable-slirp=system
      --enable-vde
      --extra-cflags=-DNCURSES_WIDECHAR=1
      --disable-sdl
      --disable-gtk
    ]
    # Sharing Samba directories in QEMU requires the samba.org smbd which is
    # incompatible with the macOS-provided version. This will lead to
    # silent runtime failures, so we set it to a Homebrew path in order to
    # obtain sensible runtime errors. This will also be compatible with
    # Samba installations from external taps.
    args << "--smbd=#{HOMEBREW_PREFIX}/sbin/samba-dot-org-smbd"

    args << "--enable-cocoa" if OS.mac?

    system "./configure", *args
    system "make", "V=1", "install"
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/qemu-system-xtensa --version")
  end
end
