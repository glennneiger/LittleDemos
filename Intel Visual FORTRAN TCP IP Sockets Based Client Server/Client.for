        PROGRAM CLIENT
            USE WS2_32

            IMPLICIT NONE 

            INTEGER CONNECTION_DROPPED_BY_REMOTE_PARTY

            INTEGER SUCCESS

            PARAMETER(CONNECTION_DROPPED_BY_REMOTE_PARTY = X'05050505',
     +                SUCCESS = 0)

            INTEGER GetConnection

            INTEGER SendMsg

            INTEGER ReceiveMsg

            INTEGER CloseConnection

            INTEGER connection

            TYPE T_CLIENT_SERVER_MESSAGE
                SEQUENCE
                    ! The fields in this TYPE must share memory space with a dummy CHARACTER variable
                    ! In this instance the ClientSendCount field from the first UNION MAP and the buffer CHARACTER variable from the
                    ! second UNION map both start at the same memory address (i.e. they overlay one another in memory)
                    ! The buffer CHARACTER variable is required because the Win32 send and recv routines accept a
                    ! CHARACTER variable whose address is the starting memory address of the message to be sent or received,
                    ! respectively
                    UNION
                        MAP
                            INTEGER ClientSendCount
                            INTEGER ServerSendCount
                        END MAP
                        MAP
                            CHARACTER buffer
                        END MAP
                    END UNION
            END TYPE

            TYPE(T_CLIENT_SERVER_MESSAGE) clientServerMessage

            INTEGER status

            INTEGER idx


            status = GetConnection(connection)
            IF (status .EQ. SUCCESS) THEN
                DO idx = 1, 10
                    clientServerMessage%ClientSendCount =
     +                    clientServerMessage%ClientSendCount + 1

                    WRITE(*, *) clientServerMessage%ClientSendCount,
     +                          clientServerMessage%ServerSendCount

                    status = SendMsg(connection,
     +                               clientServerMessage%buffer,
     +                               SIZEOF(clientServerMessage))
                    IF (status .NE. SUCCESS) THEN
                        WRITE(*, *) 'SendMsg - ', status
                    ENDIF

                    status = ReceiveMsg(connection,
     +                                  clientServerMessage%buffer,
     +                                  SIZEOF(clientServerMessage))
                    IF (status .NE. SUCCESS) THEN
                        WRITE(*, *) 'ReceiveMsg - ', status
                    ENDIF

                    WRITE(*, *) clientServerMessage%ClientSendCount,
     +                          clientServerMessage%ServerSendCount

                ENDDO
            ELSE
                WRITE(*, '(A, Z12)') 'GetConnection - ', status
            ENDIF

            status = CloseConnection(connection)

            PAUSE
        STOP
        END

        INTEGER FUNCTION GetConnection(connection)
            USE WS2_32

            IMPLICIT NONE 

            INTEGER WINSOCK_V2_2

            INTEGER SUCCESS

            PARAMETER(WINSOCK_V2_2 = X'202',
     +                SUCCESS = 0)

            INTEGER connection

            TYPE(T_SOCKADDR_IN) connectionInfo

            TYPE(T_WSADATA) wsaInfo

            CHARACTER*15 host

            INTEGER*2 port

            INTEGER status


            GetConnection = SUCCESS
    
            ! Initialize Winsock v2.
            status = WSAStartup(WINSOCK_V2_2, wsaInfo)
            IF (status .NE. SUCCESS) THEN
                GetConnection = status

                RETURN
            ENDIF

            connection = socket(AF_INET, SOCK_STREAM, IPPROTO_TCP)
            IF (connection .EQ. INVALID_SOCKET) THEN
                GetConnection = INVALID_SOCKET

                status = WSACleanup()

                RETURN
            ENDIF

            host = '127.0.0.1'
            port = 55000

            connectionInfo%sin_family = AF_INET
            connectionInfo%sin_port = htons(port)
            connectionInfo%sin_addr%s_addr =
     +                     inet_addr(host(1:LEN_TRIM(host)))

            status = connect(connection,
     +                       %REF(connectionInfo),
     +                       SIZEOF(connectionInfo))
            IF (status .EQ. SOCKET_ERROR) THEN
                GetConnection = WSAGetLastError()

                RETURN
            ENDIF

            RETURN
        END FUNCTION

        INTEGER FUNCTION SendMsg(connection, buffer, size)
            USE WS2_32

            IMPLICIT NONE 

            INTEGER SUCCESS

            PARAMETER(SUCCESS = 0)

            INTEGER connection

            INTEGER size

            CHARACTER*(size) buffer

            INTEGER bytesSent
            INTEGER bytesSentTotal

            INTEGER status


            SendMsg = SUCCESS

            bytesSent = 0
            bytesSentTotal = 0

            DO WHILE (bytesSentTotal < size)
                bytesSent = send(connection,
     +                           buffer(bytesSentTotal + 1:
     +                                  bytesSentTotal + 1),
     +                           (size - bytesSentTotal),
     +                           0)
                IF (bytesSent .EQ. SOCKET_ERROR) THEN
                    SendMsg = WSAGetLastError()

                    RETURN
                ENDIF
        
                bytesSentTotal = bytesSentTotal + bytesSent
            END DO

            RETURN
        END

        INTEGER FUNCTION ReceiveMsg(connection, buffer, size)
            USE WS2_32

            IMPLICIT NONE 

            INTEGER CONNECTION_DROPPED_BY_REMOTE_PARTY

            INTEGER SUCCESS

            PARAMETER(CONNECTION_DROPPED_BY_REMOTE_PARTY = X'05050505',
     +                SUCCESS = 0)

            INTEGER connection

            INTEGER size

            CHARACTER*(size) buffer

            INTEGER bytesReceived
            INTEGER bytesReceivedTotal

            INTEGER status


            ReceiveMsg = SUCCESS

            bytesReceived = 0
            bytesReceivedTotal = 0

            DO WHILE (bytesReceivedTotal < size)
                bytesReceived = recv(connection,
     +                               buffer(bytesReceivedTotal + 1:
     +                                      bytesReceivedTotal + 1),
     +                               (size - bytesReceivedTotal),
     +                               0)
                IF (bytesReceived .EQ. SOCKET_ERROR) THEN
                    ReceiveMsg = WSAGetLastError()

                    RETURN
                ELSEIF (bytesReceived .EQ. 0) THEN
                    ReceiveMsg = CONNECTION_DROPPED_BY_REMOTE_PARTY

                    RETURN
                ENDIF
        
                bytesReceivedTotal = bytesReceivedTotal + bytesReceived
            END DO

            RETURN
        END

        INTEGER FUNCTION CloseConnection(connection)
            USE WS2_32

            IMPLICIT NONE 

            INTEGER SUCCESS

            PARAMETER(SUCCESS = 0)

            INTEGER connection

            INTEGER status


            CloseConnection = SUCCESS

            status = closesocket(connection)

            status = WSACleanup()

            RETURN
        END