#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <netinet/in.h>
#include <sys/socket.h>
#define PORT 8080
#define MAX 1024
void handle_client(int client_socket) {
   char buffer[MAX];
   int bytes_read;
   while (1) {
       // Clear the buffer
       bzero(buffer, MAX);
       // Read data from the client
       bytes_read = read(client_socket, buffer, sizeof(buffer));
       if (bytes_read <= 0) {
           printf("Client disconnected.\n");
           break;
       }
       printf("Received from client: %s", buffer);
       // Echo the data back to the client
       write(client_socket, buffer, strlen(buffer));
       // Exit if the client sends "exit"
       if (strncmp("exit", buffer, 4) == 0) {
           printf("Server exiting...\n");
           break;
       }
   }
   close(client_socket);
}
int main() {
   int server_socket, client_socket;
   struct sockaddr_in server_addr, client_addr;
   socklen_t addr_len;
   // Create a TCP socket
   server_socket = socket(AF_INET, SOCK_STREAM, 0);
   if (server_socket == -1) {
       perror("Socket creation failed");
       exit(EXIT_FAILURE);
   }
   printf("Socket successfully created.\n");
   // Configure server address structure
   bzero(&server_addr, sizeof(server_addr));
   server_addr.sin_family = AF_INET;
   server_addr.sin_addr.s_addr = htonl(INADDR_ANY);
   server_addr.sin_port = htons(PORT);
   // Bind the socket to the specified port
   if (bind(server_socket, (struct sockaddr*)&server_addr, sizeof(server_addr)) != 0) {
       perror("Socket bind failed");
       close(server_socket);
       exit(EXIT_FAILURE);
   }
   printf("Socket successfully binded.\n");
   // Put the server socket in listening mode
   if (listen(server_socket, 5) != 0) {
       perror("Listen failed");
       close(server_socket);
       exit(EXIT_FAILURE);
   }
   printf("Server listening on port %d...\n", PORT);
   addr_len = sizeof(client_addr);
   // Accept a client connection
   client_socket = accept(server_socket, (struct sockaddr*)&client_addr, &addr_len);
   if (client_socket < 0) {
       perror("Server accept failed");
       close(server_socket);
       exit(EXIT_FAILURE);
   }
   printf("Client connected.\n");
   // Handle client communication
   handle_client(client_socket);
   // Close the server socket
   close(server_socket);
   return 0;
}
