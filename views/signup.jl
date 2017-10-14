<extend src="layout.jl">
    <block name="body">
        <section class="hero is-fullheight is-bold is-dark">
            <include src="navbar.jl"/>
            <div class="hero-body">
                <div class="container has-text-centered">
                    <h1 class="title">Sign Up</h1>
                    <h2 class="subtitle">Use your HackForums account to securely log in to any site.</h2>

                    <div if=errors.isNotEmpty class="notification is-dark">
                        <b>Couldn't sign you up. Here's what went wrong:</b>
                        <ul>
                            <li for-each=errors>* {{ item }}</li>
                        </ul>
                    </div>

                    <form action="/signup" method="post">
                        <div class="field">
                            <div class="control has-icons-left has-icons-right">
                                <input name="email" class="input is-dark is-inverted is-outlined" type="email"
                                       placeholder="E-mail Address" required>
                                <span class="icon is-small is-left">
                                  <i class="fa fa-envelope"></i>
                                </span>
                            </div>
                        </div>

                        <div class="field">
                            <div class="control has-icons-left has-icons-right">
                                <input name="password" class="input is-dark is-inverted is-outlined" type="password"
                                       placeholder="Password" required>
                                <span class="icon is-small is-left">
                                  <i class="fa fa-key"></i>
                                </span>
                            </div>
                        </div>

                        <div class="field">
                            <div class="control has-icons-left has-icons-right">
                                <input name="confirm_password" class="input is-dark is-inverted is-outlined"
                                       type="password" placeholder="Confirm Password" required>
                                <span class="icon is-small is-left">
                                  <i class="fa fa-asterisk"></i>
                                </span>
                            </div>
                        </div>

                        <div class="field is-grouped">
                            <div class="control" style="width: 100%;">
                                <button class="button is-dark is-inverted is-outlined" style="width: 100%;">Submit</button>
                            </div>
                        </div>
                    </form>
                </div>
            </div>
        </section>
    </block>
</extend>