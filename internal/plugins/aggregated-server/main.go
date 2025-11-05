package main

import (
	"net/http"

	"github.com/gin-gonic/gin"
)

type CustomResource struct {
	Message string `json:"message"`
}

func main() {
	r := gin.New()

	r.GET("/apis/example.com/v1/custom", func(ctx *gin.Context) {
		resp := CustomResource{Message: "Hello from custom Resource API!"}
		ctx.JSON(http.StatusOK, resp)
	})

	// 实现最小的 discovery endpoint
	r.GET("/apis/example.com/v1", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, gin.H{
			"kind":         "APIResourceList",
			"apiVersion":   "v1",
			"groupVersion": "example.com/v1",
			"resources": []map[string]interface{}{
				{
					"name":         "custom",
					"singularName": "",
					"namespaced":   true,
					"kind":         "CustomResource",
					"verbs":        []string{"get", "list", "create", "update", "delete"},
				},
			},
		})
	})

	// 可选：返回 group-level discovery
	r.GET("/apis/example.com", func(ctx *gin.Context) {
		ctx.JSON(http.StatusOK, gin.H{
			"kind":       "APIGroup",
			"apiVersion": "v1",
			"name":       "example.com",
			"versions": []map[string]string{
				{"groupVersion": "example.com/v1", "version": "v1"},
			},
			"preferredVersion": map[string]string{"groupVersion": "example.com/v1", "version": "v1"},
		})
	})

	r.Run(":8080")
}
