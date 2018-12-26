<template>

	<Dialog :visible="visible">
    <template slot="title">
      {{title}}
    </template>
    <div class="dialog-contents">
      <input :class="{password: true, pin:isNumberPin}" v-model="password"
        :type="isNumberPin ? 'number' : 'password'"
        :pattern="isNumberPin ? '[0123456789]+' :'*'"
        @change="validate"/>
      <Button label="OK" :disabled="password.length < 4" @click="onOK"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import Button from '../Button.vue'

	export default {
    props: ["visible", "title", "isNumberPin"],
    data: function() {
      return {
        password: ""
      }
    },
    components: {
      Dialog,
      Button
    },
    methods: {
      onOK: function() {
        this.$emit("done", password)
      },
      validate: function() {
        if(this.isNumberPin) {
          this.$set("password", this.password.replace(/^[0-9]/g, ""));
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

  .password {
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
