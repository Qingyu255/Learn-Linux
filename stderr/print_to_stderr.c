#include <stdio.h>
#include <fcntl.h>
#include <unistd.h>

int main(void) {
	int fd = open("./a.txt", O_RDONLY);

	if (fd == -1) {
		perror("Failed to open a.txt");
return 1;
	}

	// Perform operations with fd
	close(fd);
	return 0; // success
}
