class Gtkx3 < Formula
  desc "Toolkit for creating graphical user interfaces"
  homepage "http://gtk.org/"
  url "https://download.gnome.org/sources/gtk+/3.18/gtk+-3.18.9.tar.xz"
  sha256 "783d7f8b00f9b4224cc94d7da885a67598e711c2d6d79c9c873c6b203e83acbd"

  bottle do
    sha256 "57613440207555041ff48bc234c33b0bd6c15b3548712ea3d2e080952f57d7c5" => :el_capitan
    sha256 "9193f6b6cc486ca82a8ef1486805b581b648a8e1b0f13c28da3b9e3c938df580" => :yosemite
    sha256 "ae1835f5c57fd1b6db897abff079e43e1fc2a3d34d6e8926a2861d6952206522" => :mavericks
  end

  option :universal
  option "with-quartz-relocation", "Build with quartz relocation support"

  depends_on "pkg-config" => :build
  depends_on "gdk-pixbuf"
  depends_on "jasper" => :optional
  depends_on "atk"
  depends_on "gobject-introspection"
  depends_on "libepoxy"
  depends_on "gsettings-desktop-schemas" => :recommended
  depends_on "pango"
  depends_on "glib"
  depends_on "hicolor-icon-theme"

  # Replace a keyword not supported by Snow Leopard's Objective-C compiler.
  # https://bugzilla.gnome.org/show_bug.cgi?id=756770
  if MacOS.version <= :snow_leopard
    patch do
      url "https://bugzilla.gnome.org/attachment.cgi?id=313599&format=raw"
      sha256 "a090b19d3c15364914917d9893be292225e8b8a016f2833a5b8354f079475a73"
    end
  end

  # Fixes detection of CUPS 2.x by the configure script
  # https://bugzilla.gnome.org/show_bug.cgi?id=767766
  if MacOS.version >= :sierra
    patch :p0 do
      url "https://raw.githubusercontent.com/Homebrew/formula-patches/a1fccbb34751eabe52366b8bb68bcf56ae74517c/gtk%2B3/cups.patch"
      sha256 "c1e8eb7ebf0fc75365bf76f1db11ac4ff347b9a568529b3051adaecca0573c81"
    end
  end

  def install
    ENV.universal_binary if build.universal?

    args = %W[
      --disable-debug
      --disable-dependency-tracking
      --prefix=#{prefix}
      --disable-glibtest
      --enable-introspection=yes
      --disable-schemas-compile
      --enable-quartz-backend
      --disable-x11-backend
    ]

    args << "--enable-quartz-relocation" if build.with?("quartz-relocation")

    system "./configure", *args
    # necessary to avoid gtk-update-icon-cache not being found during make install
    bin.mkpath
    ENV.prepend_path "PATH", "#{bin}"
    system "make", "install"
    # Prevent a conflict between this and Gtk+2
    mv bin/"gtk-update-icon-cache", bin/"gtk3-update-icon-cache"
  end

  def post_install
    system "#{Formula["glib"].opt_bin}/glib-compile-schemas", "#{HOMEBREW_PREFIX}/share/glib-2.0/schemas"
  end

  test do
    (testpath/"test.c").write <<-EOS.undent
      #include <gtk/gtk.h>

      int main(int argc, char *argv[]) {
        gtk_disable_setlocale();
        return 0;
      }
    EOS
    atk = Formula["atk"]
    cairo = Formula["cairo"]
    fontconfig = Formula["fontconfig"]
    freetype = Formula["freetype"]
    gdk_pixbuf = Formula["gdk-pixbuf"]
    gettext = Formula["gettext"]
    glib = Formula["glib"]
    libepoxy = Formula["libepoxy"]
    libpng = Formula["libpng"]
    pango = Formula["pango"]
    pixman = Formula["pixman"]
    flags = (ENV.cflags || "").split + (ENV.cppflags || "").split + (ENV.ldflags || "").split
    flags += %W[
      -I#{atk.opt_include}/atk-1.0
      -I#{cairo.opt_include}/cairo
      -I#{fontconfig.opt_include}
      -I#{freetype.opt_include}/freetype2
      -I#{gdk_pixbuf.opt_include}/gdk-pixbuf-2.0
      -I#{gettext.opt_include}
      -I#{glib.opt_include}/gio-unix-2.0/
      -I#{glib.opt_include}/glib-2.0
      -I#{glib.opt_lib}/glib-2.0/include
      -I#{include}
      -I#{include}/gtk-3.0
      -I#{libepoxy.opt_include}
      -I#{libpng.opt_include}/libpng16
      -I#{pango.opt_include}/pango-1.0
      -I#{pixman.opt_include}/pixman-1
      -D_REENTRANT
      -L#{atk.opt_lib}
      -L#{cairo.opt_lib}
      -L#{gdk_pixbuf.opt_lib}
      -L#{gettext.opt_lib}
      -L#{glib.opt_lib}
      -L#{lib}
      -L#{pango.opt_lib}
      -latk-1.0
      -lcairo
      -lcairo-gobject
      -lgdk-3
      -lgdk_pixbuf-2.0
      -lgio-2.0
      -lglib-2.0
      -lgobject-2.0
      -lgtk-3
      -lintl
      -lpango-1.0
      -lpangocairo-1.0
    ]
    system ENV.cc, "test.c", "-o", "test", *flags
    system "./test"
  end
end
