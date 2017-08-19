use Mojo::Base -strict;
use Mojo::File 'path';
use Mojolicious::Command::openapi;
use Mojolicious;
use Test::Mojo;
use Test::More;

my @said;
Mojo::Util::monkey_patch('Mojolicious::Command::openapi', _say => sub { push @said, @_ });

my $app = Mojolicious->new;
$app->routes->post(
  '/pets' => sub {
    my $c   = shift;
    my $res = $c->req->json;
    $res->{key} = $c->param('key');
    $c->render(openapi => $res);
  }
)->name('addPet');
$app->plugin('OpenAPI', {url => 'data://main/test.json'});

my $cmd = Mojolicious::Command::openapi->new(app => $app);
$cmd->run('/v1');
like "@said", qr{/v1 is valid}, 'validated spec from local app';

@said = ();
$cmd->run('/v1', 'addPet', -p => "key=abc", -c => '{"type":"dog"}');
like "@said", qr{"key":"abc"},  'addPet with key';
like "@said", qr{"type":"dog"}, 'addPet with type';

done_testing;

__DATA__
@@ test.json
{
  "swagger": "2.0",
  "info": { "version": "0.8", "title": "Test client spec" },
  "schemes": [ "http" ],
  "host": "api.example.com",
  "basePath": "/v1",
  "paths": {
    "/pets": {
      "post": {
        "operationId": "addPet",
        "parameters": [
          { "in": "query", "name": "key", "type": "string" },
          {
            "in": "body",
            "name": "body",
            "required": true,
            "schema": {
              "type": "object",
              "properties": {
                "type": { "type": "string", "description": "Type" }
              }
            }
          }
        ],
        "responses": {
          "200": {
            "description": "pet response",
            "schema": { "type": "object" }
          }
        }
      }
    }
  }
}