<template>

  <div class="account-container clickable" @click="summaryOpen = !summaryOpen">
    <div class="account">
      <img class="account-logo" :src="account.logo"/>
      <p class="account-name"> {{account.name}} </p>
      <p class="last-updated light-text"> Last updated: {{account.lastUpdated}} </p>
    </div>
    <transition name="roll">
      <div v-if="summaryRows.length > 0 && summaryOpen" class="summary">
        <div v-for="row in summaryRows" class="summary-row">
          <div class="summary-column">
            <p class="summary-item-label"> {{row.leftColumn.label}} </p>
            <p class="summary-item-value"> {{row.leftColumn.value}} </p>
          </div>
          <div class="summary-column">
            <p class="summary-item-label"> {{row.rightColumn.label}} </p>
            <p class="summary-item-value"> {{row.rightColumn.value}} </p>
          </div>
        </div>
      </div>
    </transition>
    <div class="bottom-gap"/>
  </div>

</template>




<script>

	export default {
    data: function() {
      return {
        summaryOpen: false
      }
    },
    computed: {
      summaryRows: function() {
        var rows = [];
        this.account.summary.map((section, i) => {
          var empty = {label: "", value: ""}
          rows.push({
            leftColumn: {
              label: section.sectionName,
              value: section.sectionValue
            },
            rightColumn: empty
          });
          section.details.map((d, j) => {
            var rightColumn = {
              label: d.name,
              value: d.value
            }
            if(j == 0) {
              rows[i].rightColumn = rightColumn;
            } else {
              rows.push({
                leftColumn: empty,
                rightColumn
              })
            }
          })
        })
        return rows;
      }
    },
    props: ["app", "account"]
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .account {
    padding-left: 8px;
    display: flex;
    align-items: center;
  }

  .account-container {
    background-color: #ffffff;
  }

  .account-container:active {
    background-color: #c9c9c9;
  }

  .account-logo {
    width: 26px;
    height: 26px;
    flex-grow: 0;
    margin-right: 16px;
  }

  .account-name {
    color: #444444;
    font-size: 16px;
    flex-grow: 0;
  }

  .last-updated {
    font-size: 12px;
    text-align: right;
    padding-bottom: 4px;
    flex-grow: 1;
  }

  .summary {
    background-color: #fbfbfb;
    border-left: 1px solid #efefef;
    overflow: hidden;
    max-height: 500px;
  }

  .roll-enter, .roll-leave-to {
    max-height: 0;
  }

  .roll-enter-active, .roll-leave-active {
    transition: max-height 0.5s;
  }

  .roll-enter-active {
    transition-timing-function: ease-in;
  }

  .roll-leave-active {
    transition-timing-function: ease-out;
  }

  .summary-row {
    display: flex;
    justify-content: flex-end;
  }

  .summary-column {
    width: 100px;
    margin: 8px 12px 16px 0;
  }

  .summary-item-label {
    font-size: 11px;
    margin: 4px 0;
    text-align: right;
    color: #959595;
  }

  .summary-item-value {
    font-size: 11px;
    margin: 4px 0;
    text-align: right;
    color: #5a5a5a;
  }

  .bottom-gap {
    margin-bottom: 18px;
  }

  .light-text {
    color: #a1a1a1;
  }

  .clickable {
    transition: background-color 0.1s ease;
  }

</style>
