<template>
    <v-container>
      <v-row>
        <v-col>
            <v-btn @click="ShowUsers">更新</v-btn>
        </v-col>
      </v-row>
  
      <v-row>
        <v-data-table
            :headers="headers"
            :items="items"
        ></v-data-table>>
      </v-row>
        
    </v-container>
  </template>
  
  <script>
    const axios = require('axios').create()
  
    export default {
      name: 'ShowUsers',
  
      data: () => ({
        headers:[
            {
                text: 'ユーザ名',
                value: 'name'
            }
        ],
        items:[
            {
                name: "ここにユーザ名が表示されます"
            }
        ]
      }),
  
      methods: {
        ShowUsers: async function(){
          const response = await axios.get('api/showusers')
          this.items = response.data
          console.log(response)
        }
      }
    }
  </script>
  