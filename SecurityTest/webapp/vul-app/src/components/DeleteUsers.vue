<template>
    <v-container>
      <v-row>
        <v-col>
            <v-btn @click="DeleteUsers">ユーザ削除</v-btn>
        </v-col>
      </v-row>        
    </v-container>
  </template>
  
  <script>
    const axios = require('axios').create()
  
    export default {
      name: 'DeleteUsers',
  
      data: () => ({
      }),
  
      methods: {
        DeleteUsers: async function(){
          const response = await axios.get('api/deleteusers')
          console.log(response)
        }
      }
    }
  </script>
  