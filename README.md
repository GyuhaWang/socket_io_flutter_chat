# socketchat
socket_io_client 를 사용한 flutter 채팅어플
<ul>
  <h5>STACK 설명</h5>
  <li>
    상태관리: riverpod (project>lib>controllers>socket_controller.dart)
  </li>
  <li>
    socket_io 서버: node, express 
  </li>
  <h5>주요 기능</h5>
  <li>
    subscribe 를 통한 방 입장이 가능합니다. (방을 만들고 해당 방에서 채팅이 이루어 질 수 있습니다.)
  </li>
  <li>
    유저 입장, 퇴장 상태를 알 수 있습니다.
  </li>
   <li>
    텍스트 입력중 상태를 알 수 있습니다.
  </li>
</ul>

## Getting Started

<ul>
  <h5>실행 이전에 설정해주세요</h5>
  <li>
    project>lib>variables.dart 안에 서버의 ipAddress를 설정해주세요.
  </li>
  <li> socket_io 서버를 실행해주세요
  <br/>
    서버는 별도의 파일로 존재합니다.
  </li>
</ul>

# Reference
  https://github.com/AhmedAbouelkher/flutter_socket_io_chat
