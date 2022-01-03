flex -o lexA.cpp lexA.l
g++ lexA.cpp -lfl -o lexA.out
./lexA.out in.txt
