#!/bin/sh
set -e

print_help () {
  echo "Run build.sh from inside the ihaskell directory to install packages in this repository:"
  echo "  ./build.sh ihaskell # Install ihaskell and its dependencies"
  echo "  ./build.sh quick    # Install ihaskell, but not its dependencies"
  echo "  ./build.sh all      # Install ihaskell, dependencies, and all display packages"
  echo "  ./build.sh display  # Install ihaskell and display libraries"
  echo
  echo "A second argument 'no-widgets' can be provided to not install ihaskell-widgets and depending packages."
  echo
  echo "If this is your first time installing ihaskell, run './build.sh ihaskell'."
}

# Verify that we're in the ihaskell directory.
if [ ! -e ihaskell.cabal ]; then
  print_help;
  exit 1
fi

if [ $# -lt 1 ]; then
    print_help;
    exit 1
fi

if [ ! $1 = "all" ] && [ ! $1 = "ihaskell" ] && [ ! $1 = "display" ] && [ ! $1 = "quick" ]; then
    print_help;
    exit 1;
fi

# What to install.
INSTALLS=""

# Remove my kernelspec
rm -rf ~/.ipython/kernels/haskell

# Compile dependencies.
if [ $# -gt 0 ]; then
  if [ $1 = "all" ] || [ $1 = "ihaskell" ]; then
    INSTALLS="$INSTALLS ghc-parser ipython-kernel"
  fi
fi

# Always make ihaskell itself
INSTALLS="$INSTALLS ."

# Install ihaskell-display packages.
if [ $# -gt 0 ]; then
  if [ $1 = "display" ] || [ $1 = "all" ]; then
        # Install all the display libraries
        cd ihaskell-display
        for dir in `ls | grep -v ihaskell-widgets`
        do
            INSTALLS="$INSTALLS ihaskell-display/$dir"
        done
        cd ..
    fi
fi

# Clean all required directories, just in case.
TOP=`pwd`
for pkg in $INSTALLS
do
    cd ./$pkg
    cabal clean
    cd $TOP
done

# Stick a "./" before everything.
INSTALL_DIRS=`echo $INSTALLS | tr ' ' '\n' | sed 's#^#./#' | tr ' ' '\n'`

echo CMD: cabal install --constraint "arithmoi -llvm" -j $INSTALL_DIRS --force-reinstalls --max-backjumps=-1 --reorder-goals
cabal install --constraint "arithmoi -llvm" -j $INSTALL_DIRS --force-reinstalls --max-backjumps=-1 --reorder-goals

if [ $2 = "no-widgets" ]; then
    echo 'Not installing ihaskell-widgets'
elif [ $1 = "display" ] || [ $1 = "all" ]; then
    cabal install ihaskell-display/ihaskell-widgets
fi

if hash ihaskell 2>/dev/null; then
    ihaskell install 2>/dev/null || echo "The command \"ihaskell install\" failed. Please check your 'ipython --version'. 3.0 or up is required. Yours is $(ipython --version)."
else
    echo "Reminder: run 'ihaskell install' to install the IHaskell kernel to Jupyter."
fi
