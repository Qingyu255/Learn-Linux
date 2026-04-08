// looking back at fork.c, So far, we haven’t done much: just created a child that prints out a
// message and exits. Sometimes, as it turns out, it is quite useful for a
// parent to wait for a child process to finish what it has been doing. This
// task is accomplished with the wait()system call (or its more complete
// sibling waitpid());

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

int main(int argc, char *argv[]) {
    printf("Hello, I am process with PID: %d\n", (int) getpid());
    int rc = fork(); // where rc is return code
    if (rc < 0) {
        perror("fork failed, failed to create child process");
        exit(1);
    } else if (rc == 0) { // child process
        printf("Hello, i am the child process (pid:%d)\n", (int) getpid());
    } else { // parent process goes here
        // where wc is wait code
        int wc = wait(NULL); // NULL means: “I don’t care about the child’s exit status.” If you do care, use: int status; wait(&status);
        // now, the parent process calls wait() to delay its execution until the child finishes executing.
        printf("Hello, I am the parent of %d (pid: %d)\n", rc, (int) getpid());
    }
    return 0;
}
