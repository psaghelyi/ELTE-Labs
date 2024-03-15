# Legkisebb dátumok

## Building the App

`$ make all` - Build the app with GCC in debug mode

`$ make all-llvm` - Build the app with LLVM in debug mode

`$ make prod` - Build the app with GCC in release mode

`$ make prod-llvm` - Build the app with LLVM in release mode

`$ make clean` - Remove the app and all build artifacts


## Running the App

`$ ./app <K> <M> <filename>` - Run the app to generate K + M number of random dates and write them to the file