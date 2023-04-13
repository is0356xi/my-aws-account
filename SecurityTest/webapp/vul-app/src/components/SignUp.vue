<template>
  <v-container>
    <v-row class="text-center">
      <v-col cols="12">
        <v-img
          :src="require('../assets/logo.svg')"
          class="my-3"
          contain
          height="200"
        />
      </v-col>
    </v-row>

    <v-row>
      <v-col>
        <form @submit.prevent="SignUp(user_name, password)">
          <v-text-field
            v-model="user_name"
            label="ユーザ名"
          >
          </v-text-field>
          
          <v-text-field
            v-model="password"
            label="パスワード"
          >
          </v-text-field>

          <v-btn type="submit">SignUp</v-btn>
        </form>
      </v-col>

      
    </v-row>

    <v-row>
      <h2>{{ singup_response }}</h2>

      <!-- <v-col>
        <v-messages :value="singup_response"></v-messages>
      </v-col> -->
    </v-row>
      
  </v-container>
</template>

<script>
  const axios = require('axios').create()

  export default {
    name: 'SignUp',

    data: () => ({
      singup_response: "サインアップステータス表示用",
      signup_values: {
        user_name: 'user_name',
        password: 'password'
      }
    }),

    methods: {
      SignUp: async function(user_name, password){
        this.signup_values.user_name = user_name
        this.signup_values.password = password

        const response = await axios.post('api/signup', this.signup_values)
        this.singup_response = response.data
        console.log(response)
      }
    }
  }
</script>
