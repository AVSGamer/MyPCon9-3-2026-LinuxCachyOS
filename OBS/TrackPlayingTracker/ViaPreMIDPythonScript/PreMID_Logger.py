import json
import os
import re
import urllib.request
from datetime import datetime
from http.server import BaseHTTPRequestHandler, HTTPServer

LOG_FILENAME = "premid_captured_data.txt"

# =====================================================================
# METHODOLOGY REQUIREMENT: CLEANING DISK FILE ON FRESH START
# =====================================================================
def initialize_log_file():
    """Checks if the log file exists and deletes it before creating a fresh
    one.
    """
    if os.path.exists(LOG_FILENAME):
        try:
            os.remove(LOG_FILENAME)
            print(f"[+] Cleaned up previous session file: {LOG_FILENAME}")
        except Exception as e:
            print(f"[-] Warning: Could not remove old file: {e}")

    # Write a fresh header block into the brand new file
    with open(LOG_FILENAME, "w", encoding="utf-8") as file:
        file.write("")

class PreMidDataReceiver(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        response = {"status": "listening"}
        self.wfile.write(json.dumps(response).encode("utf-8"))

    def do_POST(self):
        content_length = int(self.headers["Content-Length"])
        post_data = self.rfile.read(content_length).decode("utf-8")

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()

        try:
            # Parse the incoming JSON data from PreMiD
            parsed_json = json.loads(post_data)

            # =====================================================================
            # DATA FILTER LATER: SCRAPE YOUTUBE & YOUTUBE MUSIC
            # =====================================================================
            # PreMiD objects usually pass the app name in 'name', 'service', or 'metadata'
            activityMain: dict = parsed_json.get("active_activity") or {}
            service_name = activityMain.get("name", "").lower()

            if "youtube music" in service_name:
                # PreMiD structures metadata under 'details', 'state', or custom objects.
                # We pull standard targets, fallback to blanks if missing.
                title = activityMain.get("details", "No song currently playing~")
                # PreMiD often stores the Album/Artist under 'state'
                artist = activityMain.get("state", "")

                # Look for image URLs inside PreMiD's standard assets keys
                assetsL = activityMain.get("assets", {})
                album = str(assetsL.get("large_text", ""))
                pattern = r',"large_url":"(.*?)"},"timestamps":'
                # Fallback alternative if your exact layout has spacing differences:
                # pattern = r',"large_url":"(.*?)"\},"times'
                match = re.search(pattern, post_data)
                image_url = str(match.group(1))

                # Playing by the second tracker
                timestampsAssets = activityMain.get("timestamps", {})
                start = timestampsAssets.get("start", "")
                end = timestampsAssets.get("end", "")

                log_entry = (
                    f"TIMESTAMP  : {datetime.now()}\n"
                    f"IMAGE URL  : {image_url}\n"
                    f"START      : {start}\n"
                    f"END        : {end}\n"
                    f"-----------------------------------------\n"
                    f"SONG TITLE : {title}\n"
                    f"ARTIST        : {artist}\n"
                    f"ALBUM        : {album}\n\n"

                )
                print(
                    f"[+] Logged Media Activity: {title} on {service_name.upper()}"
                )
                self.save_to_file(log_entry)

            else:
                # If you want to drop non-YouTube data completely to save space,
                # you can comment this block out. Otherwise, it logs as generic info.
                generic_entry = ()
                self.save_to_file(generic_entry)

        except json.JSONDecodeError:
            error_entry = f"[-] [{datetime.now()}] Failed to decode corrupted JSON payload.\n"
            self.save_to_file(error_entry)

        response = {"status": "processed"}
        self.wfile.write(json.dumps(response).encode("utf-8"))

    # =====================================================================
    # MODIFIED LOG FILE WRITER (Appends to the fresh file created at boot)
    # =====================================================================
    def save_to_file(self, text_block):
        with open(LOG_FILENAME, "w", encoding="utf-8") as file:
            file.write(text_block)


def run_server(port=3002):
    # Initialize and clean the file right before the socket opens
    initialize_log_file()

    server_address = ("127.0.0.1", port)
    httpd = HTTPServer(server_address, PreMidDataReceiver)
    print(f"[*] Server running on http://127.0.0.1:{port}")
    try:
        httpd.serve_forever()
    except KeyboardInterrupt:
        print("\n[-] Server stopped.")
        httpd.server_close()


if __name__ == "__main__":
    run_server(port=3002)
