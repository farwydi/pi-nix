{
  lib,
  buildNpmPackage,
  fetchurl,
  jq,
  ripgrep,
  nodejs,
}:
let
  sources = lib.importJSON ./sources.json;
in
buildNpmPackage {
  pname = "pi-coding-agent";
  version = sources.version;

  src = fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${sources.version}.tgz";
    hash = sources.srcHash;
  };

  # вендорный shrinkwrap с дозаписанными integrity (см. update.sh);
  # devDependencies в shrinkwrap нет — выкидываем их, чтобы npm ci не лез в сеть
  postPatch = ''
    cp ${./npm-shrinkwrap.json} npm-shrinkwrap.json
    ${lib.getExe jq} 'del(.devDependencies)' package.json > package.json.new
    mv package.json.new package.json
  '';

  npmDepsHash = sources.npmDepsHash;

  npmFlags = [ "--omit=dev" ];

  # npm-тарбол уже содержит собранный dist/
  dontNpmBuild = true;

  postFixup = ''
    wrapProgram $out/bin/pi \
      --set PI_SKIP_VERSION_CHECK 1 \
      --prefix PATH : ${lib.makeBinPath [ ripgrep ]} \
      --suffix PATH : ${lib.makeBinPath [ nodejs ]}
  '';

  meta = {
    description = "Pi coding agent CLI";
    homepage = "https://pi.dev";
    changelog = "https://github.com/earendil-works/pi/blob/main/packages/coding-agent/CHANGELOG.md";
    license = lib.licenses.mit;
    mainProgram = "pi";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
