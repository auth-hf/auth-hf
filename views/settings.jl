<extend src="layout.jl">
    <block name="body">
        <section class="hero is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container">
                    <h1 class="title">
                        <span class="icon">
                            <i class="fa fa-cogs"></i>
                        </span>
                        <span>&nbsp;{{ user.email }}</span>
                    </h1>
                    <h2 class="subtitle">Manage your account settings here.</h2>
                </div>
            </div>
        </section>
        <section if=user.apiKey == null>
            <div class="container" style="padding-top: 1em;">
                <h1 class="title">
                    <span class="icon">
                        <i class="fa fa-key"></i>
                    </span>
                    <span>Add your API Key</span>
                </h1>
                <div class="notification">
                    Before you can start connecting with applications, you
                    need to provide Auth HF with your
                    <a href="https://hackforums.net/apikey.php" target="_blank">
                        HackForums.net API key
                    </a>. No API key is stored in plaintext; they are encrypted before
                    even reaching the database.
                    <br><br>
                    If you plan to connect your own
                    <a href="/applications">applications</a> to AuthHF,
                    your API key is needed so that we can
                    trace potential abuse back to your account
                    to protect the integrity of our users' data.
                </div>

                <form action="/settings" method="post">
                    <div class="field">
                        <div class="control has-icons-left has-icons-right">
                            <input name="api_key" class="input" placeholder="API Key" required>
                            <span class="icon is-small is-left">
                                  <i class="fa fa-key"></i>
                                </span>
                        </div>
                    </div>

                    <div class="field is-grouped">
                        <div class="control" style="width: 100%;">
                            <button class="button" style="width: 100%;">Submit</button>
                        </div>
                    </div>
                </form>
            </div>
        </section>

        <section if=user.apiKey != null>
            <div class="container" style="padding-top: 1em;">
                <h1 class="title">
                    <span class="icon">
                        <i class="fa fa-plug"></i>
                    </span>
                    <span>&nbsp;Connected Applications</span>
                </h1>
                <h2 class="subtitle">
                    You have authorized {{ tokens.length }}&nbsp;
                    <a href="/applications">application(s)</a>
                    to use your HackForums.net account.
                </h2>
                <form for-each=tokens if=item.application != null method="post" action="/settings/revoke" class="box">
                    <input name="token" type="hidden" value=item.id>
                    <article class="media">
                        <div class="media-content">
                            <div class="content">
                                <p>
                                    <strong>
                                        {{ item.application.name }}
                                    </strong>
                                    <br>
                                    {{ item.application.description }}
                                </p>
                            </div>
                        </div>
                        <div class="media-right">
                            <button class="button is-danger" type="submit">
                                <span class="icon">
                                    <i class="fa fa-trash"></i>
                                </span>
                                <span>
                                    Revoke
                                </span>
                            </button>
                        </div>
                    </article>
                </form>
            </div>
        </section>
    </block>
</extend>