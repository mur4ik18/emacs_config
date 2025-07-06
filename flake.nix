{
  description = "alex nix-darwin system flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    nix-homebrew.url = "github:zhaofengli/nix-homebrew";

    # Optional: Declarative tap management
    homebrew-core = {
      url = "github:homebrew/homebrew-core";
      flake = false;
    };
    homebrew-cask = {
      url = "github:homebrew/homebrew-cask";
      flake = false;
    };
  };

  outputs = inputs@{ self, nix-darwin, nixpkgs, nix-homebrew, homebrew-core, homebrew-cask }:
  let
    air_configuration = { pkgs, ... }: {
      # List packages installed in system profile. To search by name, run:
      # $ nix-env -qaP | grep wget
      environment.systemPackages =
        [ 
	        pkgs.emacs
          pkgs.telegram-desktop
          pkgs.discord
          pkgs.python313
          pkgs.nodejs
          pkgs.brave
	      ];

      nix-homebrew.enable = true; # https://github.com/zhaofengli/nix-homebrew
      homebrew.enable     = true;
      homebrew.brews    = ["cowsay" "stow" "libomp"];
      nixpkgs.config.allowUnfree = true;
      programs.bash.completion.enable = true;

      programs.zsh.enable = true;
      programs.zsh.enableBashCompletion = true;
      programs.zsh.enableFzfCompletion = true;
      programs.zsh.enableFzfGit = true;
      programs.zsh.enableFzfHistory = true;
      system.primaryUser = "alexkotov";
      
      # Applications
      system.defaults = {
        dock.persistent-apps = [
	        "/System/Applications/Launchpad.app"
          "/Applications/Nix Apps/Brave Browser.app"
	        "/Applications/Nix Apps/Telegram.app"
	        "/Applications/Nix Apps/Emacs.app"
          "/Applications/Nix Apps/Discord.app"
	      ];
        dock.autohide = true;
      };

      environment.variables = {
        TERM = "xterm-256color";
      };
      system.activationScripts.postActivation.text = ''
      # Following line should allow us to avoid a logout/login cycle when changing settings
      sudo -u alexkotov /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      '';

      system.defaults.CustomUserPreferences = {
        "com.apple.symbolichotkeys" = {
          AppleSymbolicHotKeys = {
            "60" = { enabled = false; };
            "61" = { enabled = false; };
            "64" = { enabled = false; };
            "65" = { enabled = false; };
            };
         };
      };

      system.keyboard.enableKeyMapping = true;
      system.keyboard.remapCapsLockToControl = true;      


      # Necessary for using flakes on this system.
      nix.settings.experimental-features = "nix-command flakes";
      
      # Enable alternative shell support in nix-darwin.
      programs.fish.enable = true;

      # Set Git commit hash for darwin-version.
      system.configurationRevision = self.rev or self.dirtyRev or null;

      # Used for backwards compatibility, please read the changelog before changing.
      # $ darwin-rebuild changelog
      system.stateVersion = 6;

      # The platform the configuration will be used on.
      nixpkgs.hostPlatform = "aarch64-darwin";
    };
  in
  {
    # Build darwin flake using:
    # $ darwin-rebuild build --flake .#Alexs-MacBook-Air
    darwinConfigurations."Alexs-MacBook-Air" = nix-darwin.lib.darwinSystem {
      modules = [ 
	      nix-homebrew.darwinModules.nix-homebrew
        {
          nix-homebrew = {
            # Install Homebrew under the default prefix
            enable = true;

            # Apple Silicon Only: Also install Homebrew under the default Intel prefix for Rosetta 2
            enableRosetta = true;

            # User owning the Homebrew prefix
            user = "alexkotov";

            # Optional: Declarative tap management
            taps = {
              "homebrew/homebrew-core" = homebrew-core;
              "homebrew/homebrew-cask" = homebrew-cask;
            };
            # Optional: Enable fully-declarative tap management
            # With mutableTaps disabled, taps can no longer be added imperatively with `brew tap`.
            mutableTaps = false;
          };
        }
	      air_configuration
      ];
    };
  };
}
