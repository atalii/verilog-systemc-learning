{
  pkgs ? import <nixpkgs> { },
}:

pkgs.mkShell {
  buildInputs = with pkgs; [
    stdenv
    verilator
    cmake
  ];

  SYSTEMC_HOME = "${pkgs.systemc}";
  CMAKE_EXPORT_COMPILE_COMMANDS = "1";
  CMAKE_PREFIX_PATH = "${pkgs.systemc}";
}
