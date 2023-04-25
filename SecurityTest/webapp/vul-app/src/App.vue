<template>
  <v-app>
    <v-main>
      <SignUp/>
      <ShowUsers/>
      <DeleteUsers/>
    </v-main>
  </v-app>
</template>

<script>
import SignUp from './components/SignUp';
import ShowUsers from './components/ShowUsers';
import DeleteUsers from './components/DeleteUsers';

export default {
  name: 'App',

  components: {
    SignUp,
    ShowUsers,
    DeleteUsers,
},

  data: () => ({
    //
  }),
};
</script>
