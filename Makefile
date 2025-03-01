all: exec_prime

exec_prime: prime
	./prime

prime: prime.o
	ld prime.o -o prime

prime.o: prime_number.s
	nasm -f elf64 -g -o prime.o prime_number.s

clean:
	rm prime.o prime