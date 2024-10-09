const express = require('express');
const { createServer } = require('node:http');
const { join } = require('node:path');
const { Server } = require('socket.io');

const app = express();
const server = createServer(app);
const io = new Server(server);

app.get('/', (req, res) => {
	res.sendFile(join(__dirname, 'index.html'));
});

io.on('connection', function (socket) {
	console.log(`Connection : SocketId = ${socket.id}`);

	var userName = '';

	socket.on('subscribe', function (data) {
		console.log('subscribe trigged');
		var room_data = data;
		userName = room_data.userName;
		const roomName = room_data.roomName;

		socket.join(`${roomName}`);
		console.log(`Username : ${userName} joined Room Name : ${roomName}`);

		io.to(`${roomName}`).emit('newUserToChatRoom', { userName });
	});

	socket.on('unsubscribe', function (data) {
		console.log('unsubscribe trigged');
		const room_data = data;
		const userName = room_data.userName;
		const roomName = room_data.roomName;

		console.log(`Username : ${userName} leaved Room Name : ${roomName}`);
		// socket.broadcast.to(`${roomName}`).emit('userLeftChatRoom', { userName })
		io.to(`${roomName}`).emit('userLeftChatRoom', { userName });
		socket.leave(`${roomName}`);
	});

	socket.on('newMessage', function (data) {
		console.log('newMessage triggered');

		const messageData = data;
		const messageContent = messageData.messageContent;
		const roomName = messageData.roomName;

		console.log(`[Room Number ${roomName}] ${userName} : ${messageContent}`);
		// Just pass the data that has been passed from the writer socket

		const chatData = {
			userName: userName,
			messageContent: messageContent,
			roomName: roomName,
		};
		socket.broadcast
			.to(`${roomName}`)
			.emit('updateChat', JSON.stringify(chatData)); // Need to be parsed into Kotlin object in Kotlin
	});

	socket.on('typing', function (roomNumber) {
		//Only roomNumber is needed here
		console.log('typing triggered');
		socket.broadcast.to(`${roomNumber}`).emit('typing');
	});

	socket.on('stopTyping', function (roomNumber) {
		//Only roomNumber is needed here
		console.log('stopTyping triggered');
		socket.broadcast.to(`${roomNumber}`).emit('stopTyping');
	});

	socket.on('disconnect', function () {
		console.log('One of sockets disconnected from our server.');
	});
});

server.listen(3000, () => {
	console.log('server running at http://localhost:3000');
});
