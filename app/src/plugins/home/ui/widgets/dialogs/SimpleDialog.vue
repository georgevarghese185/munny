<template>

	<Dialog :visible="visible">
		<div class="dialog-contents">
			<p class="message"> {{message}} </p>
			<Button label="OK" @click="onOkClick"/>
		</div>
	</Dialog>

</template>




<script>
	import Dialog from './Dialog.vue'
	import Button from '../Button.vue'

	export default {
		props: ["message", "visible"],
		components: { Dialog, Button },
		methods: {
			onOkClick: function() {
				this.$emit("done");
			}
		}
	}

</script>




<style scoped>

	p {
		font-family: sans-serif;
		font-size: 18px;
		text-align: center;
	}

	.dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
    padding: 12px 12px;
  }

</style>
