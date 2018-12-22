<template>

	<Dialog :visible="visible">
    <template slot="title">
      How do want to encrypt the sensitive information?
    </template>
    <div class="dialog-contents">
      <RadioSelector :options="encryptOptions" @select="onSelect"/>
      <Button label="OK" :disabled="selected == null" @click="onOK"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import RadioSelector from '../RadioSelector.vue'
  import Button from '../Button.vue'

	export default {
    props: ["visible", "encryptOptions"],
    data: function() {
      return {
        selected: null
      }
    },
    methods: {
      onSelect: function(selected) {
        this.selected = selected;
      },
      onOK: function() {
        this.$emit("encryptionSelct", this.selected);
      }
    },
    components: {
      Dialog,
      RadioSelector,
      Button
    }
  }

</script>




<style scoped>

  .dialog-contents {
    display: flex;
    flex-direction: column;
    align-items: center;
    margin-top: 18px;
    padding: 12px 12px;
  }

</style>
