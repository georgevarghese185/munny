<template>

	<div :class="buttonStyle" @click="onClick"> {{label}} </div>

</template>




<script>

	export default {
    props: ["label", "disabled"],
    computed: {
      buttonStyle: function() {
        return {
          button: true,
          "enabled-button": !this.disabled,
          "disabled-button": this.disabled
        }
      }
    },
		methods: {
			onClick: function() {
				if(!this.disabled) {
					this.$emit("click")
				}
			}
		}
  }

</script>




<style scoped>

  .button {
    font-family: sans-serif;
    display: flex;
    align-items: center;
    justify-content: center;
    height: 42px;
    min-width: 150px;
    border-radius: 30px;
    color: #ffffff;
    margin-top: 28px;
    transition: background-color 0.1s;
  }

  .enabled-button {
    background-color: #393939;
  }

  .enabled-button:active {
    background-color: #5e5d5d;
  }

  .disabled-button {
    background-color: #9a9a9a;
  }

</style>
