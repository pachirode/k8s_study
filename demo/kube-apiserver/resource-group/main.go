package main

import "github.com/gin-gonic/gin"

func main() {
	router := gin.Default()

	apiGroup := router.Group("/api/v1")
	{
		apiGroup.GET("/healthz", func(context *gin.Context) {
			context.JSON(200, gin.H{
				"status": "ok",
			})
		})
		apiGroup.GET("/", func(context *gin.Context) {
			context.JSON(200, gin.H{
				"message": "Hello World",
			})
		})
	}

	router.Run(":8080")
}
