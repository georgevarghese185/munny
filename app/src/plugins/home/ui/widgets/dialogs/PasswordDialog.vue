<template>

	<Dialog :visible="visible">
    <template slot="title">
      {{title}}
    </template>
    <div class="dialog-contents">
      <input :class="{'text-input': true, pin:isNumberPin}" v-model="input"
        :type="isNumberPin ? 'number' : (isPassword ? 'password' : '')"
        :pattern="isNumberPin ? '[0123456789]+' :'*'"
        @change="validate"/>
      <Button label="OK" :disabled="input.length < 4" @click="onOK"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import Button from '../Button.vue'

	const InputTypes = {
		TEXT: "text",
		PASSWORD: "password",
		NUMBER_PASSWORD: "number_password"
	}

	export { InputTypes }

	export default {
    props: ["visible", "title", "inputType"],
    data: function() {
      return {
        input: ""
      }
    },
		computed: {
			isPassword: function() {
				return this.inputType == InputTypes.PASSWORD || this.inputType == InputTypes.NUMBER_PASSWORD;
			},
			isNumberPin: function() {
				return this.inputType == InputTypes.NUMBER_PASSWORD;
			}
		},
    components: {
      Dialog,
      Button
    },
		watch: {
			inputType: function() {
				this.input = "";
			}
		},
    methods: {
      onOK: function() {
        this.$emit("done", input)
      },
      validate: function() {
        if(this.isNumberPin) {
					this.input = this.input.replace(/^[0-9]/g, "");
        }
      }
    }
  }

</script>




<style scoped>

  .dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 24px;
    padding: 12px 12px;
  }

  .text-input {
    border: 1px solid #000000;
    background-color: #ffffff;
    font-size: 18px;
    width: 90%;
    height: 42px;
    -webkit-text-security: disc;
  }

  .pin {
    text-align: center;
  }

</style>
