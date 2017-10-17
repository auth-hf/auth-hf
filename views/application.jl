<extend src="layout.jl">
    <block name="body">
        <section class="hero is-bold is-dark">
            <include src="navbar.jl" />
            <div class="hero-body">
                <div class="container">
                    <h1 class="title">
                        <span class="icon">
                            <i class="fa fa-laptop"></i>
                        </span>
                        <span>&nbsp;&nbsp;{{ app.name }}</span>
                    </h1>
                    <h2 class="subtitle">Edit your application.</h2>
                </div>
            </div>
        </section>
        <section class="section">
            <form action="/applications/" + app.id method="post">
                <input name="csrf_token" type="hidden" value=csrf_token>

                <table class="table table is-hoverable">
                    <thead>
                        <tr>
                            <th colspan="2">OAuth2 Credentials</th>
                        </tr>
                    </thead>
                    <tbody>
                        <tr>
                            <td>
                                <b>Public Key</b>
                            </td>
                            <td>
                                {{ app.publicKey }}
                            </td>
                        </tr>
                        <tr>
                            <td>
                                <b>Secret Key</b>
                            </td>
                            <td>
                                <div class="button is-dark" id="showButton">
                                    <span class="icon">
                                        <i class="fa fa-eye"></i>
                                    </span>
                                    <span>
                                        Show
                                    </span>
                                </div>
                                <span id="secretKey" style="display: none;">
                                    {{ app.secretKey }}
                                </span>
                            </td>
                        </tr>
                    </tbody>
                </table>

                <!--<input name="csrf_token" type="hidden" value=csrf_token>-->

                <div class="field">
                    <p class="control has-icons-left" style="width: 100%;">
                        <span class="select" style="width: 100%;">
                            <select name="mode" style="width: 100%;" required>
                                <option value="">Choose an Action...</option>
                                <option value="edit" selected="selected">Edit Application</option>
                                <option value="delete">DELETE APPLICATION (IRREVERSIBLE!!!)</option>
                            </select>
                        </span>
                        <span class="icon is-small is-left">
                            <i class="fa fa-question"></i>
                        </span>
                    </p>
                </div>

                <div class="field">
                    <label class="label">Name</label>
                    <div class="control has-icons-left has-icons-right">
                        <input name="name" class="input" placeholder="Application Name" value=app.name required=true>
                        <span class="icon is-small is-left">
                          <i class="fa fa-laptop"></i>
                        </span>
                    </div>
                </div>

                <div class="field">
                    <div class="control">
                        <label class="label">Description</label>
                        <textarea name="description" class="textarea" placeholder="Briefly describe your application" rows="5" required>
                            {{ app.description }}
                        </textarea>
                    </div>
                </div>

                <div class="field">
                    <div class="control">
                        <label class="label">
                            Valid Redirect URI's
                        </label>
                        <textarea name="redirect_uris" class="textarea" placeholder="Separate with a comma (,)" rows="5" required>
                            {{ app.redirectUris }}
                        </textarea>
                    </div>
                </div>

                <button class="button is-dark" type="submit" style="width: 100%">
                    Submit
                </button>
            </form>
        </section>
    </block>

    <block name="js">
        <script src="/js/application.js"></script>
    </block>
</extend>