class CvsFastExport < Formula
  desc "Export an RCS or CVS history as a fast-import stream"
  homepage "https://gitlab.com/esr/cvs-fast-export"
  url "https://gitlab.com/esr/cvs-fast-export/-/archive/1.50/cvs-fast-export-1.50.tar.gz"
  sha256 "5e5e2ffdbd4a2c89acd45969c7d4895a5c93b11ada19480aae5bf5a2a6bc62de"
  head "https://gitlab.com/esr/cvs-fast-export.git"

  depends_on "asciidoc" => :build
  # Can't use bison provided by macOS because it's not new enough
  # and doesn't support the constructs used by this project.
  depends_on "bison" => :build
  depends_on "docbook-xsl" => :build
  depends_on "flex" => :build
  depends_on "cvs"
  depends_on "python"
  depends_on "rcs"
  depends_on "rsync"

  def install
    inreplace "cvssync", %r{^#!/usr/bin/python}, "#!/usr/bin/env python"
    inreplace "tests/Makefile", /\becho\b/, "/bin/echo"

    args = ["prefix=#{prefix}"]
    args << "VERSION=#{latest_head_version}" if head?

    ENV["XML_CATALOG_FILES"] = "#{etc}/xml/catalog"

    system "make", *args
    ENV.deparallelize { system "make", "check" }
    system "make", "install", *args
  end

  test do
    cvsroot = testpath/"cvsroot"
    cvsuser = testpath/"cvsuser"
    gitrepo = testpath/"gitrepo"

    cvsroot.mkpath
    cvsuser.mkpath
    gitrepo.mkpath

    # Create the initial fake CVS repository.
    system "cvs", "-d", cvsroot, "init"

    # This is the CVS root!
    ENV["CVSROOT"] = cvsroot

    chdir cvsuser do
      # Import module 'mymodule' as vendor=homebrew tag=start.
      system "cvs", "import", "-m", "created my module", "mymodule", "homebrew", "start"
      # And check it out.
      system "cvs", "checkout", "mymodule"
      # Enter the module.
      chdir "mymodule" do
        # Create a dummy file in the freshly created module.
        File.open("testfile.txt", "w") do |f|
          f.write("This is a test file!")
        end
        # Add the file to the CVS repository.
        system "cvs", "add", "testfile.txt"
        # And commit!
        system "cvs", "commit", "-m", "test commit"
      end
    end

    # Now, find all files in the CVS root repository.
    files = Dir["#{cvsroot}/**/*"]

    odebug "Files", files.join(" ")

    # Pipe the concatenated list of files to cvs-fast-exporter and
    # save the fast-export result.
    fast_export = pipe_output("#{bin}/cvs-fast-export", files.join("\n"), 0)

    odebug "Fast Export", fast_export

    # Initialize the target git repository.
    system "git", "init", gitrepo

    chdir gitrepo do
      # Pipe the stream to git via fast-import.
      pipe_output("git fast-import 2>&1", fast_export, 0)

      # Checkout the import.
      system "git", "checkout"

      # Now check that the commit matches.
      assert_equal "test commit", shell_output("git log -1 --pretty=format:%s").chomp

      # And the file contents too.
      assert_equal "This is a test file!", File.read("testfile.txt").chomp
    end
  end
end
