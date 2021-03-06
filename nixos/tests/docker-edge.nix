# This test runs docker and checks if simple container starts

import ./make-test.nix ({ pkgs, ...} : {
  name = "docker";
  meta = with pkgs.stdenv.lib.maintainers; {
    maintainers = [ nequissimus offline ];
  };

  nodes = {
    docker =
      { pkgs, ... }:
        {
          virtualisation.docker.enable = true;
          virtualisation.docker.package = pkgs.docker-edge;

          users.users = {
            noprivs = {
              isNormalUser = true;
              description = "Can't access the docker daemon";
              password = "foobar";
            };

            hasprivs = {
              isNormalUser = true;
              description = "Can access the docker daemon";
              password = "foobar";
              extraGroups = [ "docker" ];
            };
          };
        };
    };

  testScript = ''
    startAll;

    $docker->waitForUnit("sockets.target");
    $docker->succeed("tar cv --files-from /dev/null | docker import - scratchimg");
    $docker->succeed("docker run -d --name=sleeping -v /nix/store:/nix/store -v /run/current-system/sw/bin:/bin scratchimg /bin/sleep 10");
    $docker->succeed("docker ps | grep sleeping");
    $docker->succeed("sudo -u hasprivs docker ps");
    $docker->fail("sudo -u noprivs docker ps");
    $docker->succeed("docker stop sleeping");

    # Must match version twice to ensure client and server versions are correct
    $docker->succeed('[ $(docker version | grep ${pkgs.docker-edge.version} | wc -l) = "2" ]');
  '';
})
