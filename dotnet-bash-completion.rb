class DotnetBashCompletion < Formula
  desc "Bash Completion for dotnet CLI"
  homepage "https://docs.microsoft.com/en-us/dotnet/core/tools/enable-tab-autocomplete"
  url "https://raw.githubusercontent.com/dotnet/sdk/e80cf181f715697b88f18845d095bb9b623f325a/scripts/register-completions.bash"
  version "3.1.7"
  sha256 "90c1931ceb1f91b3535147761668b854e90c042a7fc138b7fec08b8a18961afc"
  license "MIT"
  revision 1

  bottle do
    root_url "https://github.com/jasonkarns/homebrew-homebrew/releases/download/dotnet-completion-3.1.7_1"
    sha256 cellar: :any_skip_relocation, big_sur: "7312b3e4026a1d1c28cb24ab831b0b7a975df5940a2326bed440dd18bcacf466"
  end

  def install
    bash_completion.install "register-completions.bash" => "dotnet"
  end

  test do
    assert_match "complete -f -F _dotnet_bash_complete dotnet",
      shell_output(". #{bash_completion}/dotnet && complete -p dotnet")
  end
end
