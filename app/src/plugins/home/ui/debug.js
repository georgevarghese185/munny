import HomeScreen from './HomeScreen.vue'
import Vue from 'vue'

(function(){
  var vm = new Vue({
    el: "#root",
    render: createElement => createElement(HomeScreen, {
      props: {
        app: {
          name: "Munny",
          pluginDir: "home"
        },
        accounts: [
          {
            name: "ICICI",
            logo: "bank_logos/icici.png",
            lastUpdated: "4 hours ago",
            summaryRows:[
              {
                leftColumn: {
                  label: "Savings Account",
                  value: "XXXXXX1234"
                },
                rightColumn: {
                  label: "Balance",
                  value: "7655"
                }
              }
            ],
            sync: {
              status: "syncing",
              message: "Logging in..."
            }
          },
          {
            name: "HDFC",
            logo: "bank_logos/hdfc.png",
            lastUpdated: "4 hours ago",
            summaryRows: [
              {
                leftColumn: {
                  label: "Savings Account",
                  value: "XXXXXX1091"
                },
                rightColumn: {
                  label: "Balance",
                  value: "20000"
                }
              },
              {
                leftColumn: {
                  label: "Credit Card",
                  value: "XXXXXX2011"
                },
                rightColumn: {
                  label: "Credit Balance",
                  value: "80500"
                }
              }
            ],
            sync: {
              status: "syncing",
              message: "Submitting OTP..."
            }
          }
        ],
        services: ["ICICI Bank", "HDFC Bank"],
        encryptOptions: [
          "Encrypt using screen lock",
          "Encrypt with a PIN",
          "Encrypt with a password",
          "Don't bother (Bad Idea)"
        ],
        viewers: [
          "Debug Viewer"
        ]
      }
    })
  })
})()
