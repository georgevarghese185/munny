<template>

	<Dialog :visible="visible">
    <div class="dialog-contents">
      <Selector :options="services" @select="onSelect"/>
      <Button label="OK" :disabled="selectedService == null" @click="onOK"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'
  import Selector from '../Selector.vue'
  import Button from '../Button.vue'

	export default {
    props: ["visible", "services"],
    data: function() {
      return {
        selectedService: null
      }
    },
    components: {
      Dialog,
      Selector,
      Button
    },
    methods: {
      onSelect: function(selection) {
        this.selectedService = selection;
      },
      onOK: function() {
        if(this.selectedService != null) {
          this.$emit("done", this.selectedService)
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

</style>
