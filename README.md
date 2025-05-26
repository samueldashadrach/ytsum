# README

 - Download youtube videos using yt-dlp and summarise them using openai o3.
 - Runs client side. To run server side, obtain cookie from a residential internet connection and pass it to yt-dlp running on server.
 - yt-dlp here could be outdated, go get original from the original repo
 - Make sure to connect VPN for videos that are blocked in your country

Example

```
export OPENAI_API_KEY="sk-whatever"
./ytsum.sh https://www.youtube.com/watch?v=AVE0fXbAvBQ
```
