<template>

	<div class="dialog-contents">
    <p class="sensitive light-text"> *Sensitive </p>
    <input class="field" type="email" placeholder="Customer ID" v-model="customerId"/>
    <p class="sensitive light-text"> *Sensitive </p>
    <input class="field" type="password" placeholder="Password" v-model="password"/>
    <p class="sensitive-note light-text"> *Sensitive fields will be encrypted and stored on your device </p>
    <Button label="OK" @click="onOkClick"/>
  </div>

</template>




<script>
  import Button from 'src/plugins/home/ui/widgets/Button.vue';

	export default {
		props: ["initialState", "onEvent"],
		data: function() {
			return {
				customerId: this.initialState.customerId,
				password: this.initialState.password
			}
		},
		methods: {
			onOkClick: function() {
				this.onEvent("SettingsDone", this.customerId, this.password)
			}
		},
    components: { Button }
  }

</script>




<style scoped>

  p {
    font-family: sans-serif;
  }

  .dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
  }

  .field {
    background-color: #ffffff;
    border: 1px solid #000000;
    padding: 0 8px;
    height: 42px;
    width: 90%;
  }

  .sensitive {
    width: 90%;
    margin: 14px 0 4px 0;
    padding-left: 20px;
  }

  .sensitive-note {
    margin-top: 32px;
    width: 90%;
  }

  .light-text {
    font-size: 11px;
    color: #8e8e8e;
  }

</style>
