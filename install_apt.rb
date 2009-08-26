APT_PACKAGES = {
  '.rb' => 'ruby',
  '.pl' => 'perl',
  '.py' => 'python',
  '.php' => 'php5-cli',
  '.scm' => 'gauche',
  '.l' => 'clisp',
  '.js' => 'spidermonkey-bin',
  '.lua' => 'lua5.1',
  '.tcl' => 'tcl8.4',
#  '.xtal' => '',
  '.st' => 'gnu-smalltalk',
  '.pro' => 'swi-prolog',
  '.for' => 'gforth',
  '.bas' => 'yabasic',
  '.pl6' => 'pugs',
  '.erl' => 'erlang',
#  '.ijs' => '',
  '.a+' => 'aplus-fsf',
#  '.mind' => '',
  '.c' => 'gcc',
  '.cpp' => 'g++',
#  '.d' => '',
  '.ml' => 'ocaml',
  '.hs' => 'ghc6',
  '.ada' => 'gnat',
  '.m' => 'gobjc',
  '.java' => 'gcj',
  '.pas' => 'gpc',
  '.f95' => 'gfortran',
  '.cs' => 'mono-mcs',
  '.cob' => 'open-cobol',
#  '.curry' => '',
  '.awk' => 'mawk',
  '.sed' => 'sed',
  '.sh' => 'bash',
#  '.xgawk' => '',
  '.m4' => 'm4',
  '.ps' => 'ghostscript',
  '.vhdl' => 'ghdl',
  '.bf' => 'beef',
  '.ws' => 'whitespace',
#  '.bef' => '',
#  '.pef' => '',
#  '.ms' => '',
#  '.gs' => '',
  '.unl' => 'unlambda',
#  '.lazy' => '',
#  '.wr' => '',
#  '.di' => '',
  '.s' => 'binutils',
#  '.out' => '',
#  '.z8b' => '',
  '.vi' => 'vim',
#  '.grb' => '',
}

def install_apt
  system("sudo apt-get install -y #{APT_PACKAGES.values*' '}")
end