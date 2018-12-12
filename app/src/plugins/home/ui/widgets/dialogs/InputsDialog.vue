<template>

	<Dialog :visible="visible">
    <template slot="title">
      {{serviceName}} requires the following inputs
    </template>
    <div class="dialog-contents">
      <div id="service-inputs"/>
    </div>
  </Dialog>

</template>




<script>
  import Dialog from './Dialog.vue'

	export default {
    props: ["serviceName", "visible"],
    components: {
      Dialog
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
