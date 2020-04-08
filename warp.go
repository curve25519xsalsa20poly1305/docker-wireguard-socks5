package main

import (
	"crypto/rand"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"io"
	"io/ioutil"
	"net/http"
	"strings"
	"time"

	"golang.org/x/crypto/curve25519"
)

func check(err error) {
	if err != nil {
		panic(err)
	}
}

type response struct {
	Result *struct {
		ID      string
		Type    string
		Model   string
		Name    string
		Key     string
		Account *struct {
			ID                       string
			AccountType              string `json:"account_type"`
			Created                  *time.Time
			Updated                  *time.Time
			PremiumData              uint `json:"premium_data"`
			Quota                    uint
			Usage                    uint
			WarpPlus                 bool `json:"warp_plus"`
			ReferralCount            uint `json:"referral_count"`
			ReferralRenewalCountdown uint `json:"referral_renewal_countdown"`
			Role                     string
			License                  string
		}
		Config *struct {
			ClientID string `json:"client_id"`
			Peers    []struct {
				PublicKey string `json:"public_key"`
				Endpoint  *struct {
					V4   string
					V6   string
					Host string
				}
			}
			Interface *struct {
				Addresses *struct {
					V4 string
					V6 string
				}
			}
			Services *struct {
				HTTPProxy string `json:"http_proxy"`
			}
		}
		Token           string
		WarpEnabled     bool `json:"warp_enabled"`
		WaitlistEnabled bool `json:"waitlist_enabled"`
		Created         *time.Time
		Updated         *time.Time
		Tos             *time.Time
		Place           uint
		Locale          string
		Enabled         bool
		InstallID       string `json:"install_id"`
		FCMToken        string `json:"fcm_token"`
	}
	Success  bool
	Errors   []string
	Messages []string
}

func main() {

	pk := new([32]byte)
	sk := new([32]byte)
	_, err := io.ReadFull(rand.Reader, sk[:])
	check(err)

	curve25519.ScalarBaseMult(pk, sk)

	reqBody := strings.NewReader(`{"key":"` + base64.StdEncoding.EncodeToString(pk[:]) + `","tos":"` + time.Now().Format(time.RFC3339) + `","type":"ios","model":"iPhone11,6","fcm_token":"","device_token":""}`)

	req, err := http.NewRequest("POST", "https://api.cloudflareclient.com/v0i2003111800/reg", reqBody)
	check(err)

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "*/*")
	req.Header.Set("User-Agent", "1.1.1.1/2003111800.1")
	req.Header.Set("Accept-Language", "en-us")

	res, err := http.DefaultClient.Do(req)
	check(err)

	resBytes, err := ioutil.ReadAll(res.Body)
	check(err)

	var response *response
	err = json.Unmarshal(resBytes, &response)
	check(err)

	reqBody = strings.NewReader(`{"warp_enabled":true}`)

	req, err = http.NewRequest("PATCH", "https://api.cloudflareclient.com/v0i2003111800/reg/"+response.Result.ID, reqBody)
	check(err)

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("Accept", "*/*")
	req.Header.Set("User-Agent", "1.1.1.1/2003111800.1")
	req.Header.Set("Accept-Language", "en-us")
	req.Header.Set("Authorization", "Bearer "+response.Result.Token)

	res, err = http.DefaultClient.Do(req)
	check(err)

	fmt.Println(`[Interface]
PrivateKey = ` + base64.StdEncoding.EncodeToString(sk[:32]) + `
DNS = 1.1.1.1
Address = ` + response.Result.Config.Interface.Addresses.V4 + `/32

[Peer]
PublicKey = ` + response.Result.Config.Peers[0].PublicKey + `
AllowedIPs = 0.0.0.0/0
Endpoint = 162.159.192.5:2408
`)
}
