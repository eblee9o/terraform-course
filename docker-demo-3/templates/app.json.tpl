[
  {
    "name": "myapp",
    "image": "${REPOSITORY_URL}:${APP_VERSION}",
    "essential": true,
    "cpu": 256,
    "memory": 256,
    "portMappings": [
      { "containerPort": 3000, "hostPort": 3000, "protocol": "tcp" }
    ],
    "healthCheck": {
      "command": ["CMD-SHELL", "curl -fsS http://localhost:3000/health || exit 1"],
      "interval": 30,
      "timeout": 5,
      "retries": 3,
      "startPeriod": 10
    },
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "/ecs/myapp",
        "awslogs-region": "eu-west-1",
        "awslogs-stream-prefix": "ecs"
      }
    }
  }
]

