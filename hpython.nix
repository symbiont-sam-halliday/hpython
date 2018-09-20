{ mkDerivation, base, bifunctors, bytestring, containers, criterion
, deepseq, deriving-compat, digit, directory, dlist, filepath
, fingertree, hedgehog, lens, megaparsec, mtl, parsers
, parsers-megaparsec, process, semigroupoids, stdenv, text, these
, transformers
}:
mkDerivation {
  pname = "hpython";
  version = "0.1.0.0";
  src = ./.;
  isLibrary = true;
  isExecutable = true;
  libraryHaskellDepends = [
    base bifunctors bytestring containers deriving-compat digit dlist
    fingertree lens megaparsec mtl parsers parsers-megaparsec
    semigroupoids text these
  ];
  executableHaskellDepends = [ base lens text ];
  testHaskellDepends = [
    base digit directory filepath hedgehog lens megaparsec mtl process
    semigroupoids text these transformers
  ];
  benchmarkHaskellDepends = [
    base criterion deepseq megaparsec text
  ];
  license = stdenv.lib.licenses.bsd3;
}
