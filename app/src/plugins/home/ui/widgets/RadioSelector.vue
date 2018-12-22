<template>

	<div class="radio-selector">
    <div v-for="option in options" :key="option" class="radio-option clickable" @click="onOptionClick(option)">
      <div class="radio-circle">
        <div class="radio-circle-fill" v-if="selected == option"/>
      </div>
      <p class="radio-option-text"> {{option}} </p>
    </div>
	</div>

</template>




<script>

	export default {
    props: ["options"],
    methods: {
      onOptionClick: function(option) {
        this.selected = option;
        this.$emit("select", option)
      }
    },
    data: function() {
      return {
        selected: null
      }
    }
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
    margin: 14px 0;
  }

	.radio-selector {
    width: 100%;
    display: flex;
    flex-direction: column;
  }

  .radio-option {
    display: flex;
    align-items: center;
    background-color: #ffffff;
  }

  .radio-option:active {
    background-color: #c9c9c9;
  }

  .radio-circle {
    display: flex;
    align-items: center;
    justify-content: center;
    width: 18px;
    height: 18px;
    border: 1px solid #707070;
    border-radius: 100px;
    margin-right: 18px;
  }

  .radio-circle-fill {
    width: 12px;
    height: 12px;
    background-color: #000000;
    border-radius: 100px;
  }

  .clickable {
    transition: background-color 0.1s;
  }

</style>
