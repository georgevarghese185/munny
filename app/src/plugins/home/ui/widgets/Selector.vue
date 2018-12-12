<template>

  <select class="default-style" v-model="selected" @change="onChange">
    <option disabled value="">Choose a Service...</option>
    <option v-for="option in options"> {{option}} </option>
  </select>

</template>




<script>

	export default {
    props: ["options"],
    data: function() {
      return {
        selected: ''
      }
    },
    methods: {
      onChange: function() {
        this.$emit("select", this.selected)
      }
    }
  }

</script>




<style scoped>

.default-style {
  border: 1px solid #000000;
  background-color: #ffffff;
  font-size: 18px;
  width: 90%;
  height: 42px;
}

</style>
