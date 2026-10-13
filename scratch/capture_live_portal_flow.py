import time
import os
import sys
from selenium import webdriver
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.common.by import By
import urllib.request
import json
import ssl

def setup_driver(width=1280, height=850, is_mobile=False):
    opts = Options()
    opts.add_argument('--headless=new')
    opts.add_argument('--ignore-certificate-errors')
    opts.add_argument('--allow-insecure-localhost')
    opts.add_argument('--no-sandbox')
    opts.add_argument('--disable-gpu')
    opts.add_argument(f'--window-size={width},{height}')
    if is_mobile:
        opts.add_argument('--user-agent=Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36')
    driver = webdriver.Chrome(options=opts)
    driver.set_window_size(width, height)
    return driver

def run_capture():
    url = 'https://127.0.0.1:53317/'
    screenshots_dir = os.path.abspath('documentation/screenshots')
    os.makedirs(screenshots_dir, exist_ok=True)
    
    test_file_path = os.path.abspath('sample_network_experiment.txt')
    with open(test_file_path, 'w', encoding='utf-8') as f:
        f.write('Hotspot Guardian Computer Networks Experiment Report Data File.\nTransferred over local 802.11 Wi-Fi hotspot via HTTPS Web Portal streaming protocol.\n')
    
    # Desktop View & RTT Test
    print("Capturing Desktop View & RTT...")
    driver = setup_driver(1280, 1000)
    try:
        driver.get(url)
        time.sleep(2)
        driver.save_screenshot(os.path.join(screenshots_dir, 'fig4_web_portal_desktop.png'))
        print("Saved fig4_web_portal_desktop.png")
        
        # Test Ping RTT
        try:
            ping_btn = driver.find_element(By.XPATH, "//button[contains(text(), 'Ping Server')]")
            ping_btn.click()
            time.sleep(1.5)
            driver.save_screenshot(os.path.join(screenshots_dir, 'fig5_web_portal_rtt_ping.png'))
            print("Saved fig5_web_portal_rtt_ping.png")
        except Exception as e:
            print("Ping test error:", e)
            
        # Two-Way Live Chat Test
        try:
            msg_input = driver.find_element(By.ID, "msgInput")
            send_btn = driver.find_element(By.ID, "sendMsgBtn")
            msg_input.clear()
            msg_input.send_keys("Hello Laptop! Connected via Mobile Browser Portal (Client IP: 10.66.85.129)")
            send_btn.click()
            time.sleep(1.5)
            
            # Post a Host message
            ctx = ssl.create_default_context()
            ctx.check_hostname = False
            ctx.verify_mode = ssl.CERT_NONE
            req_data = json.dumps({"sender": "Laptop Host (Teacher)", "text": "Message acknowledged! Hotspot Guardian link is verified active."}).encode('utf-8')
            req = urllib.request.Request(
                'https://127.0.0.1:53317/api/hotspot/message',
                data=req_data,
                headers={'Content-Type': 'application/json'}
            )
            try:
                urllib.request.urlopen(req, context=ctx)
            except Exception as ex:
                pass
                
            time.sleep(3) # Wait for 2.5s poll
            driver.save_screenshot(os.path.join(screenshots_dir, 'fig6_web_portal_chat_messages.png'))
            print("Saved fig6_web_portal_chat_messages.png")
        except Exception as e:
            print("Chat test error:", e)

        # File Upload Test
        try:
            # Overwrite alert to not block
            driver.execute_script("window.alert = function(msg) { console.log('ALERT:', msg); };")
            file_input = driver.find_element(By.ID, "fileInput")
            file_input.send_keys(test_file_path)
            time.sleep(1)
            upload_btn = driver.find_element(By.ID, "uploadBtn")
            upload_btn.click()
            time.sleep(2)
            try:
                alert = driver.switch_to.alert
                alert.accept()
            except Exception:
                pass
            driver.save_screenshot(os.path.join(screenshots_dir, 'fig7_web_portal_file_upload.png'))
            print("Saved fig7_web_portal_file_upload.png")
        except Exception as e:
            print("File upload test error:", e)

        # Activity Journal Screenshot
        try:
            log_box = driver.find_element(By.ID, "logBox")
            driver.execute_script("arguments[0].scrollIntoView();", log_box)
            time.sleep(1)
            driver.save_screenshot(os.path.join(screenshots_dir, 'fig10_event_journal_network_log.png'))
            print("Saved fig10_event_journal_network_log.png")
        except Exception as e:
            print("Log box capture error:", e)

    finally:
        driver.quit()
        
    # Mobile Phone Viewport Capture
    print("Capturing Mobile View...")
    mobile_driver = setup_driver(412, 915, is_mobile=True)
    try:
        mobile_driver.get(url)
        time.sleep(2)
        # Test ping on mobile too
        try:
            ping_btn = mobile_driver.find_element(By.XPATH, "//button[contains(text(), 'Ping Server')]")
            ping_btn.click()
            time.sleep(1.5)
        except Exception:
            pass
        mobile_driver.save_screenshot(os.path.join(screenshots_dir, 'fig8_web_portal_mobile_view.png'))
        print("Saved fig8_web_portal_mobile_view.png")
    finally:
        mobile_driver.quit()

if __name__ == '__main__':
    run_capture()
